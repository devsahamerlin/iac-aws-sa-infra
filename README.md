# AWS Terraform Intro

Provisions an AWS infrastructure including a VPC and a Web Server instance. Demonstrates the use of modules, variables, outputs, and an local, Terraform cloud and S3 backend.

## Infrastructure Components

- **VPC Module (`developers-vpc`)**: Creates a VPC with public and private subnets.
- **Web Server Module (`webserver1`)**: Provisions an EC2 instance acting as a web server.

## Prerequisites

- Terraform `>= 1.2.0`
- AWS Account with Access Key and Secret Key

## Setup

Set your AWS credentials as environment variables or provide them via `terraform.tfvars`.

```bash
export AWS_ACCESS_KEY="your_access_key"
export AWS_SECRET_KEY="your_secret_key"
```

## Usage

1.  **Initialize Terraform**:
    ```bash
    terraform init
    ```

2.  **Plan the infrastructure**:
    ```bash
    terraform plan
    ```

3.  **Apply the changes**:
    ```bash
    terraform apply
    ```

## Inputs

| Name | Description | Default |
|------|-------------|---------|
| `aws_region` | AWS Region to deploy resources | `us-east-2` |
| `cidr_block` | CIDR block for the VPC | `172.16.0.0/16` |
| `aws_access_key` | AWS Access Key | (sensitive) |
| `aws_secret_key` | AWS Secret Key | (sensitive) |
| `ami_id` | AMI ID for the EC2 instance | `ami-0c5ddb3560e768732` |

## Outputs

- `developers-vpc-id`: The ID of the created VPC.
- `developers-vpc-public-subnet-id`: The ID of the public subnet.
- `developers-vpc-private-subnet-id`: The ID of the private subnet.
- `web-server-public_ip`: The public URL of the web server.

## Backend

This project uses an **S3 backend** to store the state file.
- **Bucket**: `tfc-iac-bucket`
- **Region**: `us-east-1`
- **Key**: `states/dev/terraform.tfstate`

Recommendation: create specific policy with least privilege for S3 Bucket

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowListBucket",
      "Effect": "Allow",
      "Action": ["s3:ListBucket"],
      "Resource": "arn:aws:s3:::tfc-iac-bucket",
      "Condition": {
        "StringLike": {
          "s3:prefix": ["states/*"]
        }
      }
    },
    {
      "Sid": "AllowBucketObjectsCRUD",
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject"
      ],
      "Resource": "arn:aws:s3:::tfc-iac-bucket/states/*"
    }
  ]
}
```

Ensure you have access to this S3 bucket or configure a different backend in `versions.tf`.

## EKs

```shell
aws configure

# pour le cluster "standard"
aws eks --region us-east-2 update-kubeconfig --name $(terraform output -raw eks_cluster_name)

# liste les contextes kube
kubectl config get-contexts

# vérifier le contexte courant (vous pouvez changer si besoin)
kubectl config current-context

# lister les nodes
kubectl get nodes

# lister les pods dans tous les namespaces
kubectl get pods -A

# lister les services (utile pour vérifier LoadBalancer)
kubectl get svc -A

kubectl apply -f nginx.yml

kubectl expose deployment nginx-test --port=80 --target-port=80 --type=LoadBalancer

kubectl get svc nginx-test -o wide
# ou
kubectl get svc -w nginx-test

# forwarder le port 8080 local vers le pod/deployment
kubectl port-forward deployment/nginx-test 8080:80
# puis accéder à http://localhost:8080

kubectl delete svc nginx-test
kubectl delete deployment nginx-test
```

## Deploy E-commerce Microservices

```shell
kubectl apply -f https://github.com/aws-containers/retail-store-sample-app/releases/latest/download/kubernetes.yaml
kubectl get pods -A
kubectl get svc -A
kubectl get svc -o wide
kubectl get svc ui -o wide

kubectl describe pod ui
kubectl get events --sort-by='.metadata.creationTimestamp'

kubectl logs deployment/ui

kubectl config get-contexts

```

## supprimer les resources creer par les microservice

```shell
kubectl delete -f nginx.yml
kubectl delete -f https://github.com/aws-containers/retail-store-sample-app/releases/latest/download/kubernetes.yaml
```

### Troublleshoot Resource if not deleted

```shell
# Lister tous les LBs encore actifs dans la région
aws elb describe-load-balancers --query "LoadBalancerDescriptions[*].LoadBalancerName" --output table
aws elbv2 describe-load-balancers --query "LoadBalancers[*].{Name:LoadBalancerName,State:State.Code}" --output table

# Supprimer l'ELB classique
aws elb delete-load-balancer --load-balancer-name a4446c647255d42d5b518b5f61041b6d

# Vérifier les LBs v2 (ALB/NLB)
aws elbv2 describe-load-balancers \
  --query "LoadBalancers[*].{Name:LoadBalancerName,ARN:LoadBalancerArn,State:State.Code}" \
  --output table

VPC_ID=vpc-0487860d3d0b87d2e

aws ec2 describe-security-groups \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --query "SecurityGroups[?GroupName!='default'].{ID:GroupId,Name:GroupName}" \
  --output table

aws ec2 delete-security-group --group-id sg-056d45efbe445f75b
```