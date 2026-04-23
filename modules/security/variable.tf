variable "vpc_id" {
  description = "VPC ID for security group"
  type        = string
}

variable "my_ip" {
  description = "Allowed IP for ingress"
  type        = string
}
