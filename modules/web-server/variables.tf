variable "aws_region" {
  type = string
}

variable "server_name" {
  type = string
}
variable "web_server_port" {
  type = number
}
variable "instance_type" {
  type = string
}

variable "ami_id" {
  default = "ami-0c5ddb3560e768732"
}

variable "subnet_id" { }
variable "private_ips" {}
variable "vpc_id" {}