module "vpc" {
  source       = "../../modules/vpc"
  cluster_name = var.cluster_name
}

module "eks" {
  source                           = "../../modules/eks"
  cluster_name                     = var.cluster_name
  cluster_version                  = var.cluster_version
  vpc_id                           = module.vpc.vpc_id
  private_subnets                  = module.vpc.private_subnets
  endpoint_public_access_cidrs     = var.cluster_endpoint_public_access_cidrs
  node_instance_types              = var.node_instance_types
  node_capacity_type               = var.node_capacity_type
  cloudwatch_log_retention_in_days = var.cloudwatch_log_retention_in_days
  access_entries                   = local.github_actions_access_entries
}
