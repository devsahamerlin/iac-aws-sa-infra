# Infrastructure AWS — Déploiement de Microservices sur EKS avec Terraform

---

## 1. Vue d'ensemble

Ce projet provisionne, via Terraform, une infrastructure AWS production-grade destinée à héberger des applications microservices conteneurisées sur Kubernetes. L'infrastructure sert de socle pour des workloads concrets : une application e-commerce distribuée ([AWS Retail Store Sample App](https://github.com/aws-containers/retail-store-sample-app)) composée de plusieurs services indépendants (UI, catalogue, panier, commandes, paiement), ainsi qu'une application de démonstration (jeu 2048) avec autoscaling horizontal.

**Pattern illustré : IaC → Cluster managé → Workloads microservices**

```
Terraform (IaC)
    │
    ├── Module VPC    ──▶  Réseau isolé multi-AZ, segmenté par usage
    ├── Module EKS    ──▶  Cluster Kubernetes managé (standard ou auto-mode)
    └── Module Web    ──▶  EC2 optionnel (point d'entrée alternatif)
                               │
                               ▼
                    kubectl apply
                               │
              ┌────────────────┼──────────────────┐
              ▼                ▼                  ▼
         nginx-test      retail-store          demo-game
         (smoke test)    (e-commerce           (2048 + HPA)
                          multi-services)
```

L'objectif n'est pas seulement de déployer un cluster — c'est de démontrer qu'une infrastructure Terraform bien structurée peut absorber n'importe quel workload Kubernetes sans modification du code d'infrastructure.

---

## 2. Architecture Technique

### Vue réseau

```
┌─────────────────────────────────────────────────────────────────────┐
│  VPC  10.0.0.0/16  (developers-vpc)                                 │
│                                                                     │
│  ┌─────────────────────────────┐  ┌──────────────────────────────┐  │
│  │  Subnet public (web)        │  │  Subnets publics EKS x2      │  │
│  │  10.0.2.0/24                │  │  10.0.5.0/24  (AZ-a)         │  │
│  │  └─ EC2 Web Server (opt.)   │  │  10.0.6.0/24  (AZ-b)         │  │
│  └─────────────────────────────┘  │  └─ Node Group EKS           │  │
│                                   │     t3.medium  (2→3 nodes)   │  │
│  ┌─────────────────────────────┐  └──────────────────────────────┘  │
│  │  Subnet privé (web)         │  ┌──────────────────────────────┐  │
│  │  10.0.1.0/24                │  │  Subnets privés EKS x2       │  │
│  └─────────────────────────────┘  │  10.0.3.0/24  (AZ-a)         │  │
│                                   │  10.0.4.0/24  (AZ-b)         │  │
│                                   └──────────────────────────────┘  │
│                                                                     │
│  Internet Gateway ──▶ Route Table publique ──▶ 0.0.0.0/0           │
└─────────────────────────────────────────────────────────────────────┘
```

### Topologie des sous-réseaux

| Sous-réseau | CIDR | AZ | Usage |
|-------------|------|----|-------|
| `public` (web) | `10.0.2.0/24` | — | Serveur web EC2 (optionnel) |
| `private` (web) | `10.0.1.0/24` | — | Workloads internes |
| `cluster_public[0]` | `10.0.5.0/24` | AZ-a | Nodes EKS — microservices |
| `cluster_public[1]` | `10.0.6.0/24` | AZ-b | Nodes EKS — microservices |
| `cluster_private[0]` | `10.0.3.0/24` | AZ-a | Réservé (prod : nodes privés) |
| `cluster_private[1]` | `10.0.4.0/24` | AZ-b | Réservé (prod : nodes privés) |

### Modules Terraform et leurs dépendances

```
module.developers-vpc
    └── output: cluster_public_subnet_ids
            │
            └──▶ module.eks (subnet_ids)
                     └── aws_eks_cluster.this
                     └── aws_eks_node_group.main
                     └── aws_eks_access_entry.iac_user  ──▶ var.cluster_admin_user
```

### IAM — Rôles provisionnés par le module EKS

| Rôle | Assumé par | Politiques attachées |
|------|-----------|---------------------|
| `eks-standard-<name>-role` | `eks.amazonaws.com` | `AmazonEKSClusterPolicy` |
| `standard-eks-node-role` | `ec2.amazonaws.com` | `AmazonEKSWorkerNodeMinimalPolicy` · `AmazonEC2ContainerRegistryPullOnly` · `AmazonEKS_CNI_Policy` |

### Node Group

| Paramètre | Valeur |
|-----------|--------|
| Instance type | `t3.medium` |
| Desired | `2` |
| Min | `1` |
| Max | `3` |
| Subnets | `cluster_public_subnet_ids` (2 AZ) |
| Rolling update `max_unavailable` | `1` |

### Outputs exposés

**Module VPC :**

| Output | Description |
|--------|-------------|
| `vpc_id` | ID du VPC |
| `public_subnet_id` | ID subnet public web |
| `private_subnet_id` | ID subnet privé web |
| `cluster_public_subnet_ids` | Liste des 2 IDs subnets publics EKS |
| `cluster_private_subnet_ids` | Liste des 2 IDs subnets privés EKS |
| `aws_availability_zones` | AZ disponibles dans la région |

**Module EKS :**

| Output | Description |
|--------|-------------|
| `cluster_name` | Nom du cluster |
| `cluster_arn` | ARN complet |
| `cluster_endpoint` | URL de l'API server |
| `cluster_certificate_authority_data` | CA pour kubeconfig |
| `cluster_oidc_issuer_url` | Issuer OIDC (base pour IRSA) |
| `cluster_platform_version` | Version de plateforme EKS |

### Workloads déployables

| Workload | Manifest | Type | Namespace |
|----------|----------|------|-----------|
| Nginx smoke test | `nginx.yml` | `Deployment` | `default` |
| Retail Store (e-commerce) | URL officielle AWS | Multi-`Deployment` + `Service` | `default` |
| Jeu 2048 + HPA | `k8s/demo-game.yml` | `Deployment` + `HPA` | `demo-app` |

Le manifest `demo-game.yml` inclut un **HorizontalPodAutoscaler** (minReplicas: 2 → maxReplicas: 5, seuil CPU: 70 %) et des probes `readiness`/`liveness` — configuration absente du manifest nginx, ce qui permet de comparer les deux niveaux de maturité opérationnelle.

---

## 3. Décisions d'Architecture

### Deux clusters distincts : standard vs auto-mode

Le projet maintient deux modules EKS séparés (`modules/eks` et `modules/eks-auto-mode`) plutôt qu'un seul module paramétré. Ce choix expose une différence fondamentale de paradigme :

| Dimension | EKS Standard | EKS Auto Mode |
|-----------|-------------|---------------|
| Gestion des nodes | Node Groups explicites | AWS gère le compute |
| Node pools | Manuel (`t3.medium`, scaling config) | Déclaratif (`general-purpose`) |
| Bootstrap addons | Activés par défaut | `bootstrap_self_managed_addons = false` |
| ELB intégré | Via contrôleur externe | `elastic_load_balancing.enabled = true` natif |
| Block storage | Via addon EBS CSI | `block_storage.enabled = true` natif |
| Cas d'usage | Contrôle total, coûts prévisibles | Simplification opérationnelle |

EKS Auto Mode délègue à AWS la décision de provisionnement des nodes. En contrepartie, le rôle cluster reçoit cinq politiques supplémentaires (`AmazonEKSComputePolicy`, `AmazonEKSBlockStoragePolicy`, `AmazonEKSLoadBalancingPolicy`, `AmazonEKSNetworkingPolicy`, `AmazonEKSClusterPolicy`) — surface IAM plus large, mais gestion du cycle de vie nodes entièrement managée.

### Authentification EKS : Access Entry API vs ConfigMap `aws-auth`

Le mode `authentication_mode = "API"` est utilisé à la place du `ConfigMap aws-auth` historique. Cette décision évite un anti-pattern documenté : le ConfigMap `aws-auth` est une ressource Kubernetes gérée manuellement, hors du graph Terraform, source de drift silencieux en production. L'Access Entry est une ressource AWS native (`aws_eks_access_entry`), versionnée dans l'état Terraform, et auditable via CloudTrail.

### Nodes sur subnets publics (démo) — trade-off assumé

Les nodes EKS sont placés sur `cluster_public_subnet_ids` avec `map_public_ip_on_launch = true`. En production, les nodes doivent résider sur des subnets privés avec NAT Gateway pour que le trafic sortant (pull ECR, appels AWS API) ne transite pas par une IP publique. Ce choix est documenté et intentionnel pour réduire les coûts de démonstration (pas de NAT Gateway à ~$32/mois).

### `AmazonEKSWorkerNodeMinimalPolicy` vs `AmazonEKSWorkerNodePolicy`

Le rôle node utilise la politique `Minimal` plutôt que la politique complète. La politique complète inclut des permissions `ec2:Describe*` et `elasticloadbalancing:Describe*` dont le kubelet n'a pas besoin. En cas de compromission d'un node, le blast radius est réduit.

### Séparation réseau web / cluster

Deux familles de subnets coexistent dans le même VPC : les subnets `public`/`private` dédiés à l'EC2 web server, et les subnets `cluster_public`/`cluster_private` dédiés à EKS. Cette séparation permet de supprimer le module web server sans impacter l'infrastructure EKS, et inversement.

### Backend S3 avec politique moindre privilège

L'état Terraform est stocké dans S3 avec une politique IAM décomposée en SIDs distincts : `AllowListBucket` (restreint au préfixe `states/*`) et `AllowBucketObjectsCRUD` (restreint au chemin exact). Un bucket policy trop permissif (`s3:*` sur `*`) permettrait à un token compromis de lire ou écraser n'importe quel état d'autres environnements.

---

## 4. Stack / Prérequis

| Outil | Version minimale | Rôle |
|-------|-----------------|------|
| Terraform | `>= 1.2.0` | Provisionnement IaC |
| AWS CLI | récente | Configuration credentials, mise à jour kubeconfig |
| kubectl | compatible K8s 1.31 | Déploiement et inspection des workloads |
| Compte AWS | — | Access Key + Secret Key avec droits suffisants |

### Variables requises

**Globales :**

| Nom | Description | Défaut |
|-----|-------------|--------|
| `aws_region` | Région AWS cible | `us-east-2` |
| `aws_access_key` | Clé d'accès AWS | *(sensible)* |
| `aws_secret_key` | Clé secrète AWS | *(sensible)* |

**Module VPC :**

| Nom | Description | Défaut |
|-----|-------------|--------|
| `vpc_name` | Nom du VPC | `developers-vpc` |
| `vpc_cidr_block` | CIDR du VPC | `10.0.0.0/16` |
| `vpc_public_subnet_cidr_block` | CIDR subnet public web | `10.0.2.0/24` |
| `vpc_private_subnet_cidr_block` | CIDR subnet privé web | `10.0.1.0/24` |
| `cluster_vpc_public_subnet_cidr_block` | CIDRs subnets publics EKS | `["10.0.5.0/24","10.0.6.0/24"]` |
| `cluster_vpc_private_subnet_cidr_block` | CIDRs subnets privés EKS | `["10.0.3.0/24","10.0.4.0/24"]` |
| `vpc_environment` | Tag d'environnement | `dev` |

**Module EKS :**

| Nom | Description | Défaut |
|-----|-------------|--------|
| `cluster_version` | Version Kubernetes | `1.31` |
| `cluster_role_name` | Suffixe du rôle IAM cluster | `eks-cluster` |
| `authentication_mode` | Mode d'authentification | `API` |
| `cluster_admin_user` | ARN IAM de l'admin cluster | *(requis)* |

### Politique IAM minimale pour le compte Terraform

La politique suivante couvre l'ensemble du cycle de vie EKS, réseau, IAM délégué, load balancing et observabilité. Elle est organisée par domaine fonctionnel pour faciliter l'audit et la restriction par environnement :

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "EKSClusterManagement",
      "Effect": "Allow",
      "Action": [
        "eks:CreateCluster", "eks:DeleteCluster", "eks:DescribeCluster",
        "eks:UpdateClusterConfig", "eks:UpdateClusterVersion",
        "eks:AssociateAccessPolicy", "eks:DisassociateAccessPolicy",
        "eks:CreateAccessEntry", "eks:DeleteAccessEntry", "eks:DescribeAccessEntry",
        "eks:ListAccessEntries", "eks:ListClusters",
        "eks:TagResource", "eks:UntagResource",
        "eks:DescribeAddonVersions", "eks:ListAddons"
      ],
      "Resource": "*"
    },
    {
      "Sid": "IAMRoleAndPolicyManagement",
      "Effect": "Allow",
      "Action": [
        "iam:CreateRole", "iam:DeleteRole", "iam:GetRole", "iam:UpdateRole",
        "iam:UpdateAssumeRolePolicy", "iam:AttachRolePolicy", "iam:DetachRolePolicy",
        "iam:ListRolePolicies", "iam:ListAttachedRolePolicies", "iam:GetRolePolicy",
        "iam:TagRole", "iam:UntagRole", "iam:ListRoleTags", "iam:ListInstanceProfilesForRole"
      ],
      "Resource": [
        "arn:aws:iam::*:role/*-eks-cluster-role",
        "arn:aws:iam::*:role/*-eks-node-role"
      ]
    },
    {
      "Sid": "IAMPassRole",
      "Effect": "Allow",
      "Action": "iam:PassRole",
      "Resource": [
        "arn:aws:iam::*:role/*-eks-cluster-role",
        "arn:aws:iam::*:role/*-eks-node-role"
      ],
      "Condition": {
        "StringEquals": {
          "iam:PassedToService": ["eks.amazonaws.com", "ec2.amazonaws.com"]
        }
      }
    },
    {
      "Sid": "IAMManagedPolicyReadOnly",
      "Effect": "Allow",
      "Action": ["iam:GetPolicy", "iam:GetPolicyVersion", "iam:ListPolicyVersions"],
      "Resource": [
        "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy",
        "arn:aws:iam::aws:policy/AmazonEKSComputePolicy",
        "arn:aws:iam::aws:policy/AmazonEKSBlockStoragePolicy",
        "arn:aws:iam::aws:policy/AmazonEKSLoadBalancingPolicy",
        "arn:aws:iam::aws:policy/AmazonEKSNetworkingPolicy",
        "arn:aws:iam::aws:policy/AmazonEKSWorkerNodeMinimalPolicy",
        "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPullOnly"
      ]
    },
    {
      "Sid": "VPCNetworkingCore",
      "Effect": "Allow",
      "Action": [
        "ec2:CreateVpc", "ec2:DeleteVpc", "ec2:DescribeVpcs", "ec2:ModifyVpcAttribute", "ec2:DescribeVpcAttribute",
        "ec2:CreateSubnet", "ec2:DeleteSubnet", "ec2:DescribeSubnets", "ec2:ModifySubnetAttribute",
        "ec2:CreateInternetGateway", "ec2:DeleteInternetGateway", "ec2:AttachInternetGateway",
        "ec2:DetachInternetGateway", "ec2:DescribeInternetGateways",
        "ec2:CreateRouteTable", "ec2:DeleteRouteTable", "ec2:AssociateRouteTable",
        "ec2:DisassociateRouteTable", "ec2:ReplaceRouteTableAssociation",
        "ec2:CreateRoute", "ec2:DeleteRoute", "ec2:ReplaceRoute", "ec2:DescribeRouteTables",
        "ec2:DescribeAvailabilityZones", "ec2:DescribeAccountAttributes", "ec2:DescribePrefixLists"
      ],
      "Resource": "*"
    },
    {
      "Sid": "NATGatewayAndEIP",
      "Effect": "Allow",
      "Action": [
        "ec2:AllocateAddress", "ec2:ReleaseAddress", "ec2:DescribeAddresses",
        "ec2:DescribeAddressesAttribute", "ec2:CreateNatGateway", "ec2:DeleteNatGateway", "ec2:DescribeNatGateways"
      ],
      "Resource": "*"
    },
    {
      "Sid": "SecurityGroupManagement",
      "Effect": "Allow",
      "Action": [
        "ec2:CreateSecurityGroup", "ec2:DeleteSecurityGroup", "ec2:DescribeSecurityGroups",
        "ec2:DescribeSecurityGroupRules", "ec2:AuthorizeSecurityGroupIngress",
        "ec2:AuthorizeSecurityGroupEgress", "ec2:RevokeSecurityGroupIngress",
        "ec2:RevokeSecurityGroupEgress", "ec2:ModifySecurityGroupRules",
        "ec2:UpdateSecurityGroupRuleDescriptionsIngress", "ec2:UpdateSecurityGroupRuleDescriptionsEgress"
      ],
      "Resource": "*"
    },
    {
      "Sid": "EC2TaggingGlobal",
      "Effect": "Allow",
      "Action": ["ec2:CreateTags", "ec2:DeleteTags", "ec2:DescribeTags"],
      "Resource": "*"
    },
    {
      "Sid": "ElasticLoadBalancing",
      "Effect": "Allow",
      "Action": [
        "elasticloadbalancing:CreateLoadBalancer", "elasticloadbalancing:DeleteLoadBalancer",
        "elasticloadbalancing:DescribeLoadBalancers", "elasticloadbalancing:DescribeLoadBalancerAttributes",
        "elasticloadbalancing:ModifyLoadBalancerAttributes", "elasticloadbalancing:SetSecurityGroups",
        "elasticloadbalancing:SetSubnets", "elasticloadbalancing:CreateTargetGroup",
        "elasticloadbalancing:DeleteTargetGroup", "elasticloadbalancing:DescribeTargetGroups",
        "elasticloadbalancing:DescribeTargetGroupAttributes", "elasticloadbalancing:ModifyTargetGroupAttributes",
        "elasticloadbalancing:RegisterTargets", "elasticloadbalancing:DeregisterTargets",
        "elasticloadbalancing:DescribeTargetHealth", "elasticloadbalancing:CreateListener",
        "elasticloadbalancing:DeleteListener", "elasticloadbalancing:DescribeListeners",
        "elasticloadbalancing:ModifyListener", "elasticloadbalancing:CreateRule",
        "elasticloadbalancing:DeleteRule", "elasticloadbalancing:DescribeRules",
        "elasticloadbalancing:ModifyRule", "elasticloadbalancing:AddTags",
        "elasticloadbalancing:RemoveTags", "elasticloadbalancing:DescribeTags"
      ],
      "Resource": "*"
    },
    {
      "Sid": "CloudWatchLogsForEKS",
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup", "logs:DeleteLogGroup", "logs:DescribeLogGroups",
        "logs:PutRetentionPolicy", "logs:DeleteRetentionPolicy",
        "logs:TagResource", "logs:UntagResource", "logs:ListTagsLogGroup",
        "logs:ListTagsForResource", "logs:PutLogEvents",
        "logs:CreateLogDelivery", "logs:DeleteLogDelivery", "logs:GetLogDelivery",
        "logs:UpdateLogDelivery", "logs:ListLogDeliveries"
      ],
      "Resource": "*"
    },
    {
      "Sid": "ECRPullForNodes",
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken", "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer", "ecr:BatchGetImage",
        "ecr:DescribeRepositories", "ecr:ListImages"
      ],
      "Resource": "*"
    },
    {
      "Sid": "STSCallerIdentity",
      "Effect": "Allow",
      "Action": ["sts:GetCallerIdentity"],
      "Resource": "*"
    }
  ]
}
```

### Politique IAM minimale pour le backend S3

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowListBucket",
      "Effect": "Allow",
      "Action": ["s3:ListBucket"],
      "Resource": "arn:aws:s3:::tfc-iac-bucket",
      "Condition": { "StringLike": { "s3:prefix": ["states/*"] } }
    },
    {
      "Sid": "AllowBucketObjectsCRUD",
      "Effect": "Allow",
      "Action": ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"],
      "Resource": "arn:aws:s3:::tfc-iac-bucket/states/*"
    }
  ]
}
```

> Pour utiliser un bucket différent, modifier la configuration du backend dans `versions.tf`.

---

## 5. Déploiement pas à pas

### Étape 1 — Provisionner l'infrastructure

```bash
# Configurer les credentials AWS
aws configure
# ou
export AWS_ACCESS_KEY="your_access_key"
export AWS_SECRET_KEY="your_secret_key"

# Initialiser, planifier et appliquer
terraform init
terraform plan
terraform apply
```

### Étape 2 — Connecter kubectl au cluster

```shell
# Cluster standard
aws eks --region us-east-2 update-kubeconfig --name $(terraform output -raw eks_cluster_name)

# Cluster auto-mode (si déployé)
aws eks --region us-east-2 update-kubeconfig --name $(terraform output -raw eks_auto_cluster_name)

# Vérifier le contexte actif
kubectl config get-contexts
kubectl config current-context

# Basculer manuellement si besoin
kubectl config use-context arn:aws:eks:us-east-2:949553825672:cluster/standard-eks
```

### Étape 3 — Smoke test avec Nginx

Valide que le cluster accepte des workloads et que le contrôleur LoadBalancer crée bien un ELB AWS.

```shell
kubectl apply -f nginx.yml
kubectl expose deployment nginx-test --port=80 --target-port=80 --type=LoadBalancer

# Attendre l'attribution de l'IP externe (peut prendre 2-3 min)
kubectl get svc -w nginx-test

# Alternative locale sans attendre l'ELB
kubectl port-forward deployment/nginx-test 8080:80
# → http://localhost:8080

# Nettoyage
kubectl delete svc nginx-test
kubectl delete deployment nginx-test
```

### Étape 4 — Déployer l'application e-commerce (Retail Store)

L'application [AWS Retail Store Sample App](https://github.com/aws-containers/retail-store-sample-app) illustre une architecture microservices réaliste : service `ui` (frontend), `catalog` (catalogue produits), `cart` (panier, Redis), `orders` (commandes, MySQL), `checkout` (paiement). Chaque service est un `Deployment` indépendant avec son propre `Service` Kubernetes.

```shell
kubectl apply -f https://github.com/aws-containers/retail-store-sample-app/releases/latest/download/kubernetes.yaml

# Suivre le démarrage de tous les pods (plusieurs minutes)
kubectl get pods -A -w

# Récupérer l'URL publique du frontend
kubectl get svc ui -o wide
# ou si déployé dans un namespace dédié
kubectl get svc -o wide -n retail-store
```

### Étape 5 — Déployer le jeu 2048 avec autoscaling

```shell
kubectl apply -f k8s/demo-game.yml

# Vérifier les pods dans le namespace demo-app
kubectl get pods -n demo-app
kubectl get svc -o wide -n demo-app

# Vérifier l'HPA
kubectl get hpa -n demo-app

# Attendre l'IP externe du LoadBalancer
kubectl get svc -w demo-2048-svc -n demo-app
```

---

## 6. Validation

### Vérification de l'infrastructure

```shell
# Nodes du cluster opérationnels
kubectl get nodes

# Tous les pods en Running
kubectl get pods -A

# Services avec LoadBalancer provisionné (EXTERNAL-IP != <pending>)
kubectl get svc -A
```

### Vérification des workloads microservices

```shell
# État des pods Retail Store
kubectl get pods -A | grep -v Running   # idéalement : aucune ligne

# Logs du service UI (frontend e-commerce)
kubectl logs deployment/ui

# Décrire un pod en erreur
kubectl describe pod <nom-du-pod>

# Événements triés par date (diagnostic scheduling / image pull)
kubectl get events --sort-by='.metadata.creationTimestamp'
```

### Vérification de l'autoscaling (demo-game)

```shell
# État courant de l'HPA
kubectl get hpa -n demo-app
# TARGETS affiche le % CPU courant / seuil (70%)
# REPLICAS affiche le nombre de pods actifs (2 → 5 selon charge)

# Forcer une montée en charge pour tester le scale-out
kubectl run -n demo-app load-gen --image=busybox --restart=Never -- \
  /bin/sh -c "while true; do wget -q -O- http://demo-2048-svc; done"
```

---

## 7. Nettoyage

### Procédure ordonnée

Les ressources Kubernetes créées par les déploiements (pods, services, load balancers) persistent hors du graph Terraform. Elles doivent être supprimées **avant** `terraform destroy`, sinon les Security Groups et le VPC ne peuvent pas être détruits (dépendances AWS non tracées par Terraform).

```shell
# 1. Supprimer les workloads Kubernetes
kubectl delete -f nginx.yml
kubectl delete -f https://github.com/aws-containers/retail-store-sample-app/releases/latest/download/kubernetes.yaml
kubectl delete -f k8s/demo-game.yml

# 2. Vérifier que les Load Balancers AWS ont été supprimés
aws elb describe-load-balancers --query "LoadBalancerDescriptions[*].LoadBalancerName" --output table
aws elbv2 describe-load-balancers --query "LoadBalancers[*].{Name:LoadBalancerName,State:State.Code}" --output table

# Supprimer manuellement si encore présents
aws elb delete-load-balancer --load-balancer-name <nom>

aws elbv2 describe-load-balancers \
  --query "LoadBalancers[*].{Name:LoadBalancerName,ARN:LoadBalancerArn,State:State.Code}" \
  --output table

# 3. Supprimer les Security Groups orphelins dans le VPC
VPC_ID=vpc-0487860d3d0b87d2e

aws ec2 describe-security-groups \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --query "SecurityGroups[?GroupName!='default'].{ID:GroupId,Name:GroupName}" \
  --output table

aws ec2 delete-security-group --group-id sg-056d45efbe445f75b

# 4. Détruire l'infrastructure Terraform
terraform destroy
```

> **Attention** : les Security Groups créés dynamiquement par les contrôleurs Kubernetes (notamment pour les LoadBalancers) ne sont pas toujours supprimés automatiquement lors du `terraform destroy`. Une vérification manuelle post-destruction est recommandée pour éviter tout blocage sur la suppression du VPC.

---

## 8. Évolutions possibles

| Évolution | Impact | Complexité |
|-----------|--------|-----------|
| Déplacer les nodes sur subnets privés + NAT Gateway | Sécurité production | Moyenne — ajouter `aws_nat_gateway` dans le module VPC |
| Ajouter l'AWS Load Balancer Controller (ALB Ingress) | Remplace les ELB Classic par des ALB avec path-based routing | Haute — requiert IRSA (OIDC déjà exposé en output) |
| Activer IRSA pour les pods microservices | Chaque service assume un rôle IAM distinct, sans credentials statiques | Moyenne — OIDC issuer disponible via `cluster_oidc_issuer_url` |
| Ajouter Cluster Autoscaler | Scale les nodes selon la pression des pods | Moyenne — nécessite une politique IAM supplémentaire sur le rôle node |
| Passer au cluster EKS Auto Mode | Supprime la gestion des Node Groups, ELB intégré natif | Faible — module `eks-auto-mode` déjà présent |
| Ajouter un pipeline CI/CD (GitHub Actions) | Déclenche `terraform plan/apply` sur PR | Moyenne — nécessite un rôle IAM OIDC GitHub |
| Verrouillage d'état S3 avec DynamoDB | Prévient les `apply` concurrents en équipe | Faible — ajouter `dynamodb_table` dans le backend |

---

## 9. Lessons Learned

Ces observations sont issues de l'exploitation directe de cette infrastructure, pas de la documentation officielle.

**Les Security Groups orphelins bloquent `terraform destroy`.**
Lorsqu'un `Service` Kubernetes de type `LoadBalancer` est créé, le contrôleur AWS crée automatiquement un Security Group dans le VPC. Ce Security Group n'est pas dans l'état Terraform. Si les workloads ne sont pas supprimés avant `terraform destroy`, la destruction du VPC échoue avec une erreur de dépendance. La séquence `kubectl delete → vérification AWS → terraform destroy` est non négociable.

**`kubectl get svc -w` est indispensable pour les ELB.**
L'attribution d'une `EXTERNAL-IP` sur un `LoadBalancer` peut prendre entre 90 secondes et 5 minutes selon la charge AWS. Sans le flag `-w` (watch), le diagnostic d'un provisionnement bloqué est difficile. La commande `kubectl describe svc <name>` révèle les événements sous-jacents (quota ELB, Security Group manquant, etc.).

**EKS Access Entry exige que le principal ARN existe avant l'`apply`.**
Si le `cluster_admin_user` fourni pointe vers un utilisateur IAM supprimé ou un rôle inexistant, Terraform applique le cluster mais échoue sur `aws_eks_access_entry`. L'erreur AWS n'est pas toujours explicite. Valider l'ARN avec `aws sts get-caller-identity` avant le premier `apply`.

**Les AZ disponibles ne sont pas toujours les deux premières.**
`data.aws_availability_zones.available` retourne les AZ dans un ordre non garanti selon la région et le compte AWS. Deux comptes différents dans `us-east-2` peuvent recevoir `us-east-2a`/`us-east-2b` ou `us-east-2b`/`us-east-2c`. Utiliser `count.index` sur cette datasource (comme dans le module VPC) est plus robuste que d'hardcoder les noms d'AZ.

**Le manifest Retail Store déploie ~15 ressources simultanément.**
Le premier `kubectl apply` sur le manifest e-commerce crée une douzaine de Deployments, Services, ConfigMaps et ServiceAccounts en parallèle. Certains pods (notamment `orders` avec MySQL) peuvent rester en `Init:0/1` plusieurs minutes le temps que les dépendances soient prêtes. `kubectl get events --sort-by='.metadata.creationTimestamp'` est le meilleur outil de triage.

**L'HPA ne scale pas sans metrics-server.**
Le `HorizontalPodAutoscaler` défini dans `demo-game.yml` nécessite que le metrics-server soit installé dans le cluster. Sur EKS standard, il n'est pas activé par défaut. Sans lui, `kubectl get hpa` affiche `<unknown>/70%` et aucun scaling ne se produit. Sur EKS Auto Mode, les métriques sont disponibles nativement.

---

## Le vrai gain de ces choix d'architecture

Ce projet ne se limite pas à un exercice de provisionnement. Chaque décision — modularisation Terraform, backend distant, politique IAM à moindre privilège, séparation des clusters standard/auto, gestion explicite du cycle de vie des ressources Kubernetes hors scope — traduit une posture d'ingénierie définie et documentée.

```
Ce que lit un œil non averti        Ce que perçoit un regard expérimenté
──────────────────────────────────────────────────────────────────────────────
"Il sait écrire du Terraform"        "Il structure son IaC en modules
                                      faiblement couplés, avec outputs
                                      explicites entre modules"

"Il a déployé un cluster EKS"        "Il distingue EKS standard et EKS
                                      Auto Mode, documente les trade-offs
                                      IAM surface et opérationnels"

"Il a configuré un backend S3"       "Il a appliqué le moindre privilège
                                      sur le bucket d'état, en isolant
                                      list/read/write par SID distinct"

"Il a déployé des microservices"     "Il sait que Kubernetes crée des
                                      ressources AWS hors scope Terraform,
                                      et a documenté le nettoyage manuel"

"Il a écrit des politiques IAM"      "Il a scindé les permissions par
                                      domaine fonctionnel pour minimiser
                                      le blast radius en cas de compromission"

"Il a ajouté un HPA"                 "Il sait que l'HPA est inopérant
                                      sans metrics-server sur EKS standard,
                                      et a documenté ce piège"

"Il a du code propre"                "Il pense comme un Architecte :
                                      chaque commande est contextualisée,
                                      chaque choix est traçable,
                                      chaque piège est documenté"
```
