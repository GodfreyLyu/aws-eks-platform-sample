module "vpc" {
  source       = "../../modules/vpc"
  cluster_name = var.cluster_name

}

module "eks" {
  source          = "../../modules/eks"
  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version
  vpc_id          = module.vpc.vpc_id
  private_subnets = module.vpc.private_subnets
}
