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

# VPC inputs
variable "vpc_name" {
  description = "Name tag for the VPC"
  type        = string
  default     = "developers-vpc"
}

variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "vpc_private_subnet_cidr_block" {
  description = "CIDR for the VPC private subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "vpc_public_subnet_cidr_block" {
  description = "CIDR for the VPC public subnet"
  type        = string
  default     = "10.0.2.0/24"
}

variable "cluster_vpc_private_subnet_cidr_block" {
  description = "CIDR for the VPC private subnet"
  type        = list(string)
  default     = ["10.0.3.0/24","10.0.4.0/24"]
}

variable "cluster_vpc_public_subnet_cidr_block" {
  description = "CIDR for the VPC public subnet"
  type        = list(string)
  default     = ["10.0.5.0/24","10.0.6.0/24"]
}

variable "vpc_environment" {
  description = "Environment tag for the VPC"
  type        = string
  default     = "dev"
}

# Web server inputs
variable "webserver_instance_type" {
  description = "EC2 instance type for the web server"
  type        = string
  default     = "t2.micro"
}

variable "webserver_name" {
  description = "Name for the web server"
  type        = string
  default     = "webserver"
}

variable "webserver_port" {
  description = "Port the webserver listens on"
  type        = number
  default     = 8080
}

variable "webserver_private_ips" {
  description = "List of private IPs to assign to the webserver"
  type        = list(string)
  default     = ["10.0.2.5"]
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.31"
}

variable "cluster_role_name" {
  description = "IAM role name for the standard EKS cluster"
  type        = string
  default     = "eks-cluster"
}

variable "authentication_mode" {
  description = "Authentication mode for the EKS Auto Mode cluster"
  type        = string
  default     = "API"
}


variable "cluster_admin_user" {
  type = string
  description = "Cluster admin user"
}