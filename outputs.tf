#output "vpc_id" {
#  value = aws_vpc.vpc.id
#}

output "developers-vpc-id" {
  value = module.developers-vpc.vpc_id
}

output "developers-vpc-public-subnet-id" {
  value = module.developers-vpc.public_subnet_id
}

output "developers-vpc-private-subnet-id" {
  value = module.developers-vpc.private_subnet_id
}

output "web-server-public_ip" {
  value = "http://${module.webserver1.web-server-public_ip}:8080"
}