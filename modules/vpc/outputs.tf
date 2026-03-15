output "vpc_id" {
  value = aws_vpc.vpc.id
}

output "public_subnet_id" {
  value = aws_subnet.public.id
}

output "private_subnet_id" {
  value = aws_subnet.private.id
}

output "cluster_public_subnet_ids" {
  value = aws_subnet.cluster_public[*].id
}

output "cluster_private_subnet_ids" {
  value = aws_subnet.cluster_private[*].id
}
