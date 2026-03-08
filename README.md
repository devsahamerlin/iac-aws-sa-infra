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
