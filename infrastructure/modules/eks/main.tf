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
  endpoint_public_access_cidrs             = var.endpoint_public_access_cidrs
  enable_cluster_creator_admin_permissions = true
  enabled_log_types                        = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  cloudwatch_log_group_retention_in_days   = var.cloudwatch_log_retention_in_days
  access_entries                           = var.access_entries

  addons = {
    coredns = {
      most_recent = true
    }
    eks-pod-identity-agent = {
      before_compute = true
      most_recent    = true
    }
    kube-proxy = {
      most_recent = true
    }
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
      ami_type                 = "AL2023_x86_64_STANDARD"
      capacity_type            = var.node_capacity_type
      disk_size                = 30
      instance_types           = var.node_instance_types
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

