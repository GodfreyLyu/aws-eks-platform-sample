data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

locals {
  github_actions_enabled = var.github_actions_oidc_subject != null
  github_oidc_provider_arn = var.github_oidc_provider_arn != null ? var.github_oidc_provider_arn : try(
    aws_iam_openid_connect_provider.github_actions[0].arn,
    null,
  )

  github_actions_access_entries = local.github_actions_enabled ? {
    github_actions = {
      principal_arn = aws_iam_role.github_actions_deploy[0].arn
      policy_associations = {
        application_admin = {
          policy_arn = "arn:${data.aws_partition.current.partition}:eks::aws:cluster-access-policy/AmazonEKSAdminPolicy"
          access_scope = {
            type       = "namespace"
            namespaces = [local.application_namespace]
          }
        }
      }
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
}

resource "aws_iam_role_policy" "github_actions_deploy" {
  count = local.github_actions_enabled ? 1 : 0

  name   = "${var.application_name}-deploy"
  role   = aws_iam_role.github_actions_deploy[0].id
  policy = data.aws_iam_policy_document.github_actions_deploy[0].json
}
