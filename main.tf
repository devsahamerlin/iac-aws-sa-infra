#resource "aws_vpc" "vpc" {
#  cidr_block = var.cidr_block
#
#  tags = {
#    Name = "web-server-vpc"
#  }
#}

module "developers-vpc" {
  source = "./modules/vpc"
  name   = "developers-vpc"
  cidr_block = "10.0.0.0/16"
  private_subnet_cidr_block = "10.0.1.0/24"
  public_subnet_cidr_block = "10.0.2.0/24"
  environment = "dev"
}

#module "data-science-vpc" {
#  source = "/modules/vpc"
#  name   = "web-server-vpc"
#  cidr_block = "10.0.0.0/16"
#  private_subnet_cidr_block = "10.0.1.0/24"
#  public_subnet_cidr_block = "10.0.2.0/24"
#}

module "webserver1" {
  source = "./modules/web-server"
  ami_id = var.ami_id
  aws_region = var.aws_region
  instance_type = "t2.micro"
  server_name = "webserver"
  web_server_port = 8080
  private_ips = ["10.0.2.5"]
  subnet_id = module.developers-vpc.public_subnet_id
  vpc_id = module.developers-vpc.vpc_id
}
