#############################################
# EKS Cluster Information
#############################################

output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}


output "eks_cluster_arn" {
  description = "EKS cluster ARN"
  value       = module.eks.cluster_arn
}


output "eks_cluster_version" {
  description = "Kubernetes version running on EKS cluster"
  value       = module.eks.cluster_version
}


#############################################
# Kubernetes API Access
#############################################

output "eks_cluster_endpoint" {
  description = "EKS Kubernetes API endpoint"
  value       = module.eks.cluster_endpoint
}


output "eks_cluster_certificate_authority_data" {
  description = "EKS cluster certificate authority data"
  value       = module.eks.cluster_certificate_authority_data
  sensitive   = true
}


#############################################
# VPC Networking
#############################################

output "vpc_id" {
  description = "VPC ID used by EKS"
  value       = module.vpc.vpc_id
}


output "private_subnet_ids" {
  description = "Private subnet IDs used by EKS worker nodes"
  value       = module.vpc.private_subnets
}


output "public_subnet_ids" {
  description = "Public subnet IDs used by load balancers"
  value       = module.vpc.public_subnets
}


#############################################
# Security Groups
#############################################

output "eks_cluster_security_group_id" {
  description = "EKS control plane security group ID"
  value       = module.eks.cluster_security_group_id
}


output "eks_node_security_group_id" {
  description = "EKS worker node security group ID"
  value       = module.eks.node_security_group_id
}


output "eks_primary_security_group_id" {
  description = "EKS primary security group ID"
  value       = module.eks.cluster_primary_security_group_id
}


#############################################
# IAM / IRSA
#############################################

output "eks_oidc_provider_arn" {
  description = "OIDC provider ARN for IAM Roles for Service Accounts"
  value       = module.eks.oidc_provider_arn
}


output "eks_oidc_provider" {
  description = "OIDC provider URL"
  value       = module.eks.oidc_provider
}


#############################################
# Node Groups
#############################################

output "eks_managed_node_groups" {
  description = "Managed node groups configuration"
  value       = module.eks.eks_managed_node_groups
  sensitive   = true
}


#############################################
# EKS Addons
#############################################

output "eks_cluster_addons" {
  description = "EKS addon configuration"
  value       = module.eks.cluster_addons
}


#############################################
# Operations
#############################################

output "kubectl_config_command" {
  description = "Command to configure kubectl access"

  value = format(
    "aws eks update-kubeconfig --name %s --region %s",
    module.eks.cluster_name,
    var.aws_region
  )
}

#############################################
# Application delivery
#############################################

output "application_namespace" {
  description = "Kubernetes namespace reserved for the AI agent"
  value       = kubernetes_namespace_v1.application.metadata[0].name
}

output "application_ecr_repository_name" {
  description = "ECR repository name used by the deployment workflow"
  value       = module.application_ecr.repository_name
}

output "application_ecr_repository_url" {
  description = "ECR repository URL used for the AI agent image"
  value       = module.application_ecr.repository_url
}

output "application_secret_name" {
  description = "Secrets Manager secret name; create a secret value separately so credentials never enter Terraform state"
  value       = aws_secretsmanager_secret.application.name
}

output "application_secret_arn" {
  description = "Secrets Manager secret ARN read by External Secrets Operator"
  value       = aws_secretsmanager_secret.application.arn
}

output "github_actions_deploy_role_arn" {
  description = "GitHub Actions OIDC role ARN; null when github_actions_oidc_subject is not configured"
  value       = try(aws_iam_role.github_actions_deploy[0].arn, null)
}

output "application_alb_dns_name" {
  description = "Private DNS name of the internal application ALB; it is not a public entry point"
  value       = aws_lb.application.dns_name
}

output "application_target_group_name" {
  description = "Target group referenced by the EKS TargetGroupBinding"
  value       = aws_lb_target_group.application.name
}

output "application_cloudfront_domain_name" {
  description = "CloudFront default domain name for the application"
  value       = aws_cloudfront_distribution.application.domain_name
}

output "application_url" {
  description = "Public HTTPS URL for the AI agent API"
  value       = "https://${aws_cloudfront_distribution.application.domain_name}"
}

output "application_url_command" {
  description = "Command that prints the public CloudFront HTTPS URL"
  value       = "terraform output -raw application_url"
}
