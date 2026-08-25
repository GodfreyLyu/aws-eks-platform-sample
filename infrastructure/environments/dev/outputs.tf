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