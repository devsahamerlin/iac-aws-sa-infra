#output "vpc_id" {
#  value = aws_vpc.vpc.id
#}

output "developers_vpc_id" {
  description = "VPC ID created by the developers-vpc module"
  value = module.developers-vpc.vpc_id
}

output "developers_public_subnet_id" {
  description = "Public subnet ID created by the developers-vpc module"
  value = module.developers-vpc.public_subnet_id
}

output "developers_private_subnet_id" {
  description = "Private subnet ID created by the developers-vpc module"
  value = module.developers-vpc.private_subnet_id
}

# output "webserver_public_ip" {
#   description = "Public IP/URL for the webserver"
#   value = "http://${module.webserver1.web-server-public_ip}:${var.webserver_port}"
# }

output "eks_cluster_name" {
  description = "Name of the standard EKS cluster"
  value = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "API endpoint of the standard EKS cluster"
  value = module.eks.cluster_endpoint
}

output "eks_cluster_arn" {
  description = "ARN of the standard EKS cluster"
  value = module.eks.cluster_arn
}
