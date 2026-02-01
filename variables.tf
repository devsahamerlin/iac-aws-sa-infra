variable "aws_region" {
  default = "us-east-2"
}

variable "cidr_block" {
  default = "172.16.0.0/16"
}

variable "aws_access_key" {
  sensitive = true
}

variable "aws_secret_key" {
  sensitive = true
}

variable "ami_id" {
  default = "ami-0c5ddb3560e768732"
}

