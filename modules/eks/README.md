# EKS Module

This Terraform module creates an Amazon EKS cluster and the necessary IAM role and policy attachment.

## Requirements

- Terraform >= 1.0
- AWS provider >= 5.0

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| cluster_name | Name of the EKS cluster | `string` | n/a | yes |
| cluster_version | Kubernetes version for the EKS cluster | `string` | `"1.31"` | no |
| subnet_ids | List of subnet IDs for the EKS cluster | `list(string)` | n/a | yes |
| cluster_role_name | Name of the IAM role for the EKS cluster | `string` | `"eks-cluster-example"` | no |

## Outputs

| Name | Description |
|------|-------------|
| cluster_name | Name of the EKS cluster |
| cluster_arn | ARN of the EKS cluster |
| cluster_endpoint | Endpoint of the EKS cluster |
| cluster_certificate_authority_data | Certificate authority data for the EKS cluster |
| cluster_oidc_issuer_url | OIDC issuer URL for the EKS cluster |
| cluster_platform_version | Platform version of the EKS cluster |
| cluster_status | Status of the EKS cluster |
| cluster_security_group_id | Security group ID attached to the EKS cluster |
| cluster_subnet_ids | Subnet IDs associated with the EKS cluster |
| cluster_role_arn | ARN of the IAM role for the EKS cluster |

## Usage

```hcl
module "eks" {
  source = "./modules/eks"

  cluster_name    = "my-eks-cluster"
  subnet_ids      = ["subnet-12345", "subnet-67890"]
}
```

