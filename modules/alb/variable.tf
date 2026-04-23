variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "sg_id" {
  description = "Security Group ID"
  type        = string
}

variable "private_subnets" {
  description = "Private subnet IDs for internal ALB"
  type        = list(string)
}

variable "project_name" {
  description = "Project name"
  type        = string
}
