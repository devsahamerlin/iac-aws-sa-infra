terraform {
  required_version = ">= 1.2.0"

  required_providers {

    aws = {
      source  = "hashicorp/aws"
      version = "6.28.0"
    }
  }

  # backend "local" {
  #   path = "states/terraform.tfstate"
  # }

  # backend "remote" {
  #   organization = "devsahamerlin"
  #
  #   workspaces {
  #     name = "dev-aws-iac-demo"
  #   }
  # }

  backend "s3" {
    bucket = "tfc-iac-bucket"
    region = "us-east-1"
    encrypt = true
    key    = "states/dev/terraform.tfstate"
  }

}