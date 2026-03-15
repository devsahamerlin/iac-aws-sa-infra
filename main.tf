#resource "aws_vpc" "vpc" {
#  cidr_block = var.cidr_block
#
#  tags = {
#    Name = "web-server-vpc"
#  }
#}

module "developers-vpc" {
  source = "./modules/vpc"
  name   = var.vpc_name
  cidr_block = var.vpc_cidr_block
  private_subnet_cidr_block = var.vpc_private_subnet_cidr_block
  public_subnet_cidr_block = var.vpc_public_subnet_cidr_block
  environment = var.vpc_environment
  cluster_private_subnet_cidr_block = var.cluster_vpc_private_subnet_cidr_block
  cluster_public_subnet_cidr_block = var.cluster_vpc_public_subnet_cidr_block
}

#module "data-science-vpc" {
#  source = "/modules/vpc"
#  name   = "web-server-vpc"
#  cidr_block = "10.0.0.0/16"
#  private_subnet_cidr_block = "10.0.1.0/24"
#  public_subnet_cidr_block = "10.0.2.0/24"
#}

# module "webserver1" {
#   source = "./modules/web-server"
#   ami_id = var.ami_id
#   aws_region = var.aws_region
#   instance_type = var.webserver_instance_type
#   server_name = var.webserver_name
#   web_server_port = var.webserver_port
#   private_ips = var.webserver_private_ips
#   subnet_id = module.developers-vpc.public_subnet_id
#   vpc_id = module.developers-vpc.vpc_id
# }

module "eks" {
  source = "./modules/eks"

  cluster_name    = "standard-eks"
  cluster_version = var.cluster_version
  authentication_mode = var.authentication_mode
  endpoint_private_access = false
  endpoint_public_access  = true
  cluster_role_name = "eks-standard-${var.cluster_role_name}-role"

  subnet_ids = module.developers-vpc.cluster_public_subnet_ids
  admin_principal_arn     = var.cluster_admin_user
  instance_types = ["t3.medium"]
  desired_size   = 2
  min_size       = 1
  max_size       = 3
}
