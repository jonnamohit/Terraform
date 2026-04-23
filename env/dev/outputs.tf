output "security_group_id" {
  value = module.security.security_group_id
}

output "s3_bucket_name" {
  value = module.s3.s3_bucket_name
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "alb_dns_name" {
  value = module.alb.alb_dns_name
}

output "target_group_arn" {
  value = module.alb.target_group_arn
}
