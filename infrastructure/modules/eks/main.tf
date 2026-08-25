locals {
  tags = {
    created-by = "godfrey-workshop"
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  upgrade_policy = {
    support_type = "STANDARD"
  }

  name                                     = var.cluster_name
  kubernetes_version                       = var.cluster_version
  endpoint_public_access                   = true
  enable_cluster_creator_admin_permissions = true

  addons = {
    coredns    = {}
    kube-proxy = {}
    vpc-cni = {
      before_compute = true
      most_recent    = true
      configuration_values = jsonencode({
        env = {
          ENABLE_PREFIX_DELEGATION = "true"
        }
        nodeAgent = {
          enablePolicyEventLogs = "true"
        }
        enableNetworkPolicy = "true"
      })
    }
  }

  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnets

  create_security_group      = true
  create_node_security_group = true

  eks_managed_node_groups = {
    default = {
      instance_types           = ["t3.micro"]
      force_update_version     = true
      use_name_prefix          = false
      iam_role_name            = "${var.cluster_name}-ng-default"
      iam_role_use_name_prefix = false

      min_size     = 2
      max_size     = 4
      desired_size = 2

      update_config = {
        max_unavailable_percentage = 50
      }

      labels = {
        workshop-default = "yes"
      }
    }
  }

}


