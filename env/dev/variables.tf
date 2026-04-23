variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "azs" {
  description = "Availability Zones"
  type        = list(string)
  default     = ["ap-south-2a", "ap-south-2b"]
}

variable "public_subnets_cidr" {
  description = "Public Subnets CIDR"
  type        = list(string)
  default     = ["10.0.1.0/24"]
}

variable "private_subnets_cidr" {
  description = "Private Subnets CIDR"
  type        = list(string)
  default     = ["10.0.2.0/24", "10.0.3.0/24"]
}

variable "project_name" {
  description = "Project name prefix for resources"
  type        = string
  default     = "demo"
}

variable "my_ip" {
  description = "Your IP for SG ingress (CIDR) - updated dynamically in pipeline"
  type        = string
}

variable "s3_bucket_name" {
  description = "Unique S3 bucket name for LB logs"
  type        = string
  default     = "my-lb-logs-demo-12345"
}

variable "instance_types" {
  description = "Instance types for EKS node group"
  type        = list(string)
  default     = ["t3.micro"]
}
