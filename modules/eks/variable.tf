variable "private_subnets" {
  type = list(string)
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "instance_types" {
  description = "Instance types for node group"
  type        = list(string)
  default     = ["t3.micro"]
}

variable "project_name" {
  description = "Project name prefix"
  type        = string
}
