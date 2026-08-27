locals {
  application_namespace   = var.application_name
  application_secret_name = "${var.cluster_name}/${var.environment}/${var.application_name}"
  application_secret_recovery_window_in_days = coalesce(
    var.application_secret_recovery_window_in_days,
    var.environment == "dev" ? 0 : 30,
  )
}

module "application_ecr" {
  source = "../../modules/ecr"

  repository_name = var.application_name
  tags = {
    Application = var.application_name
  }
}

resource "aws_secretsmanager_secret" "application" {
  name                    = local.application_secret_name
  description             = "Runtime secrets for ${var.application_name} on ${var.cluster_name}"
  recovery_window_in_days = local.application_secret_recovery_window_in_days

  tags = {
    Application = var.application_name
  }
}

resource "kubernetes_namespace_v1" "application" {
  metadata {
    name = local.application_namespace
    labels = {
      "app.kubernetes.io/name"                     = var.application_name
      "app.kubernetes.io/part-of"                  = var.application_name
      "app.kubernetes.io/managed-by"               = "terraform"
      "pod-security.kubernetes.io/audit"           = "restricted"
      "pod-security.kubernetes.io/enforce"         = "restricted"
      "pod-security.kubernetes.io/warn"            = "restricted"
      "pod-security.kubernetes.io/enforce-version" = "latest"
    }
  }

  depends_on = [module.eks]
}

module "aws_load_balancer_controller_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 2.8"

  name                            = "${var.cluster_name}-aws-lbc"
  attach_aws_lb_controller_policy = true

  associations = {
    controller = {
      cluster_name    = module.eks.cluster_name
      namespace       = "kube-system"
      service_account = "aws-load-balancer-controller"
    }
  }
}

resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = var.aws_load_balancer_controller_chart_version
  namespace  = "kube-system"

  atomic  = true
  timeout = 600
  wait    = true

  set = [
    {
      name  = "clusterName"
      value = module.eks.cluster_name
    },
    {
      name  = "region"
      value = var.aws_region
    },
    {
      name  = "vpcId"
      value = module.vpc.vpc_id
    },
    {
      name  = "serviceAccount.create"
      value = "true"
    },
    {
      name  = "serviceAccount.name"
      value = "aws-load-balancer-controller"
    }
  ]

  # The chart registers admission webhooks as soon as it is installed. Waiting
  # for the complete EKS module prevents those webhooks from being registered
  # before the managed node group and foundational add-ons are ready.
  depends_on = [
    module.eks,
    module.aws_load_balancer_controller_pod_identity,
  ]
}

module "external_secrets_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 2.8"

  name                                  = "${var.cluster_name}-external-secrets"
  attach_external_secrets_policy        = true
  external_secrets_secrets_manager_arns = [aws_secretsmanager_secret.application.arn]

  associations = {
    controller = {
      cluster_name    = module.eks.cluster_name
      namespace       = "external-secrets"
      service_account = "external-secrets"
    }
  }
}

resource "helm_release" "external_secrets" {
  name             = "external-secrets"
  repository       = "https://charts.external-secrets.io"
  chart            = "external-secrets"
  version          = var.external_secrets_chart_version
  namespace        = "external-secrets"
  create_namespace = true

  atomic  = true
  timeout = 600
  wait    = true

  set = [
    {
      name  = "installCRDs"
      value = "true"
    },
    {
      name  = "serviceAccount.create"
      value = "true"
    },
    {
      name  = "serviceAccount.name"
      value = "external-secrets"
    }
  ]

  # External Secrets creates Services during installation. Install it only
  # after the load balancer controller webhook has healthy endpoints.
  depends_on = [
    helm_release.aws_load_balancer_controller,
    module.external_secrets_pod_identity,
  ]
}
