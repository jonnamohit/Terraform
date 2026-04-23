module "vpc" {
  source           = "../../modules/vpc"
  project_name     = var.project_name
  aws_region       = var.aws_region
  vpc_cidr         = var.vpc_cidr
  public_subnets_cidr = var.public_subnets_cidr
  private_subnets_cidr = var.private_subnets_cidr
  azs              = var.azs
}

module "s3" {
  source      = "../../modules/s3"
  bucket_name = var.s3_bucket_name
}

module "eks" {
  source         = "../../modules/eks"
  private_subnets = module.vpc.private_subnets
  cluster_name   = "${var.project_name}-eks"
  instance_types = var.instance_types
  project_name   = var.project_name
}

module "security" {
  source = "../../modules/security"
  vpc_id = module.vpc.vpc_id
  my_ip  = var.my_ip
}

module "alb" {
  source = "../../modules/alb"

  vpc_id        = module.vpc.vpc_id
  sg_id         = module.security.security_group_id
  private_subnets = module.vpc.private_subnets
  project_name  = var.project_name
}
