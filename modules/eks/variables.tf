variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.31"
}

variable "subnet_ids" {
  description = "List of subnet IDs for the EKS cluster"
  type        = list(string)
}

variable "cluster_role_name" {
  description = "Name of the IAM role for the EKS cluster"
  type        = string
  default     = "eks-cluster-example"
}

variable "authentication_mode" {
  description = "Authentication mode for the EKS cluster"
  type        = string
  default     = "API"
}

variable "endpoint_private_access" {
  description = "Enable private access to the EKS cluster endpoint"
  type        = bool
  default     = true
}

variable "endpoint_public_access" {
  description = "Enable public access to the EKS cluster endpoint"
  type        = bool
  default     = false
}

variable "admin_principal_arn" {
  type = string
  description = "Cluster admin user"
}

variable "instance_types" {
  type    = list(string)
  default = ["t3.medium"]
}

variable "desired_size" { default = 2 }
variable "min_size"     { default = 1 }
variable "max_size"     { default = 4 }

