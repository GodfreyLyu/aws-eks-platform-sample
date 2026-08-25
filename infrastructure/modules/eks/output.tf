#############################################
# EKS Cluster Basic Information
#############################################

output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}


output "cluster_arn" {
  description = "EKS cluster ARN"
  value       = module.eks.cluster_arn
}


output "cluster_version" {
  description = "Kubernetes version running on EKS cluster"
  value       = module.eks.cluster_version
}


#############################################
# Kubernetes API Access
#############################################

output "cluster_endpoint" {
  description = "EKS Kubernetes API endpoint"
  value       = module.eks.cluster_endpoint
}


output "cluster_certificate_authority_data" {
  description = "EKS cluster CA certificate data"
  value       = module.eks.cluster_certificate_authority_data
  sensitive   = true
}


#############################################
# Networking
#############################################

output "cluster_security_group_id" {
  description = "Security group attached to EKS control plane"
  value       = module.eks.cluster_security_group_id
}


output "node_security_group_id" {
  description = "Security group attached to EKS worker nodes"
  value       = module.eks.node_security_group_id
}


output "cluster_primary_security_group_id" {
  description = "Primary security group automatically created by EKS"
  value       = module.eks.cluster_primary_security_group_id
}


#############################################
# IAM / IRSA
#############################################

output "oidc_provider_arn" {
  description = "OIDC provider ARN used for IAM Roles for Service Accounts"
  value       = module.eks.oidc_provider_arn
}


output "oidc_provider" {
  description = "OIDC provider URL without https prefix"
  value       = module.eks.oidc_provider
}


#############################################
# Managed Node Groups
#############################################

output "eks_managed_node_groups" {
  description = "EKS managed node group configuration"
  value       = module.eks.eks_managed_node_groups
  sensitive   = true
}


output "eks_managed_node_groups_autoscaling_group_names" {
  description = "Auto Scaling Group names of managed node groups"
  value       = module.eks.eks_managed_node_groups_autoscaling_group_names
}


#############################################
# IAM Roles
#############################################

output "cluster_iam_role_name" {
  description = "IAM role name used by EKS control plane"
  value       = module.eks.cluster_iam_role_name
}


output "cluster_iam_role_arn" {
  description = "IAM role ARN used by EKS control plane"
  value       = module.eks.cluster_iam_role_arn
}


#############################################
# Addons
#############################################

output "cluster_addons" {
  description = "EKS addon configuration"
  value       = module.eks.cluster_addons
}


#############################################
# Access Management
#############################################

output "access_entries" {
  description = "EKS access entries configuration"
  value       = module.eks.access_entries
  sensitive   = true
}