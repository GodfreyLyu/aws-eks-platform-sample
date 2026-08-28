data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

locals {
  github_actions_enabled          = var.github_actions_oidc_subject != null
  github_actions_kubernetes_group = "${var.application_name}-deployers"
  github_oidc_provider_arn = var.github_oidc_provider_arn != null ? var.github_oidc_provider_arn : try(
    aws_iam_openid_connect_provider.github_actions[0].arn,
    null,
  )

  github_actions_access_entries = local.github_actions_enabled ? {
    github_actions = {
      principal_arn     = aws_iam_role.github_actions_deploy[0].arn
      kubernetes_groups = [local.github_actions_kubernetes_group]
    }
  } : {}
}

resource "aws_iam_openid_connect_provider" "github_actions" {
  count = local.github_actions_enabled && var.github_oidc_provider_arn == null ? 1 : 0

  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
}

data "aws_iam_policy_document" "github_actions_assume_role" {
  count = local.github_actions_enabled ? 1 : 0

  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    principals {
      type        = "Federated"
      identifiers = [local.github_oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = [var.github_actions_oidc_subject]
    }
  }
}

resource "aws_iam_role" "github_actions_deploy" {
  count = local.github_actions_enabled ? 1 : 0

  name               = "${var.cluster_name}-${var.environment}-${var.application_name}-deploy"
  assume_role_policy = data.aws_iam_policy_document.github_actions_assume_role[0].json
}

data "aws_iam_policy_document" "github_actions_deploy" {
  count = local.github_actions_enabled ? 1 : 0

  statement {
    sid       = "GetEcrAuthorizationToken"
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    sid    = "PushApplicationImages"
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:CompleteLayerUpload",
      "ecr:GetDownloadUrlForLayer",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart",
    ]
    resources = [module.application_ecr.repository_arn]
  }

  statement {
    sid       = "DescribeEksCluster"
    effect    = "Allow"
    actions   = ["eks:DescribeCluster"]
    resources = ["arn:${data.aws_partition.current.partition}:eks:${var.aws_region}:${data.aws_caller_identity.current.account_id}:cluster/${var.cluster_name}"]
  }

  statement {
    sid    = "VerifyApplicationTargets"
    effect = "Allow"
    actions = [
      "elasticloadbalancing:DescribeTargetGroups",
      "elasticloadbalancing:DescribeTargetHealth",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "github_actions_deploy" {
  count = local.github_actions_enabled ? 1 : 0

  name   = "${var.application_name}-deploy"
  role   = aws_iam_role.github_actions_deploy[0].id
  policy = data.aws_iam_policy_document.github_actions_deploy[0].json
}

# Map the deployment role to a Kubernetes group and grant only the namespaced
# resources that are rendered by the application's EKS Kustomize overlay.
resource "kubernetes_role_v1" "github_actions_application_deployer" {
  count = local.github_actions_enabled ? 1 : 0

  metadata {
    name      = "${var.application_name}-deployer"
    namespace = kubernetes_namespace_v1.application.metadata[0].name
    labels = {
      "app.kubernetes.io/name"       = var.application_name
      "app.kubernetes.io/component"  = "delivery"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }

  rule {
    api_groups = [""]
    resources  = ["configmaps", "services"]
    verbs      = ["get", "list", "watch", "create", "update", "patch"]
  }

  rule {
    api_groups = ["apps"]
    resources  = ["deployments"]
    verbs      = ["get", "list", "watch", "create", "update", "patch"]
  }

  rule {
    api_groups = ["external-secrets.io"]
    resources  = ["externalsecrets", "secretstores"]
    verbs      = ["get", "list", "watch", "create", "update", "patch"]
  }

  rule {
    api_groups = ["elbv2.k8s.aws"]
    resources  = ["targetgroupbindings"]
    verbs      = ["get", "list", "watch", "create", "update", "patch"]
  }
}

resource "kubernetes_role_binding_v1" "github_actions_application_deployer" {
  count = local.github_actions_enabled ? 1 : 0

  metadata {
    name      = "${var.application_name}-deployer"
    namespace = kubernetes_namespace_v1.application.metadata[0].name
    labels = {
      "app.kubernetes.io/name"       = var.application_name
      "app.kubernetes.io/component"  = "delivery"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role_v1.github_actions_application_deployer[0].metadata[0].name
  }

  subject {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Group"
    name      = local.github_actions_kubernetes_group
  }
}
