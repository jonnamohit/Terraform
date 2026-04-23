variable "project_name" {
  description = "Project name for tags"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnets_cidr" {
  description = "Public subnets CIDR"
  type        = list(string)
  default     = ["10.0.1.0/24"]
}

variable "private_subnets_cidr" {
  description = "Private subnets CIDR"
  type        = list(string)
  default     = ["10.0.2.0/24", "10.0.3.0/24"]
}

variable "azs" {
  description = "Availability Zones"
  type        = list(string)
  default     = ["ap-south-2a", "ap-south-2b"]
}
