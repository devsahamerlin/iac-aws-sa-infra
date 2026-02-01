variable "public_subnet_cidr_block" {
  type = string
}

variable "private_subnet_cidr_block" {
  type = string
}

variable "name" {
  type = string
  description = "Custom VPC with 2 subnets"
}

variable "cidr_block" {
  type = string
  default = "172.20.0.0/16"
}

variable "environment" {}