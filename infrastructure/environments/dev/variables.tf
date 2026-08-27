variable "aws_region" {
  description = "AWS region for the EKS platform"
  type        = string
  default     = "ap-northeast-1"
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "eks-workshop"
}

variable "cluster_version" {
  description = "EKS cluster version."
  type        = string
  default     = "1.35"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be dev, staging, or prod."
  }
}

variable "application_name" {
  description = "Application name used for ECR, Secrets Manager, and Kubernetes resources"
  type        = string
  default     = "ai-agent-sample"

  validation {
    condition     = can(regex("^[a-z0-9]([-a-z0-9]*[a-z0-9])?$", var.application_name))
    error_message = "application_name must be a valid Kubernetes DNS label."
  }
}

variable "application_secret_recovery_window_in_days" {
  description = "Optional Secrets Manager recovery window override; null uses 0 days for dev and 30 days for staging or prod"
  type        = number
  default     = null
  nullable    = true

  validation {
    condition = (
      var.application_secret_recovery_window_in_days == null ||
      var.application_secret_recovery_window_in_days == 0 ||
      (
        var.application_secret_recovery_window_in_days >= 7 &&
        var.application_secret_recovery_window_in_days <= 30 &&
        floor(var.application_secret_recovery_window_in_days) == var.application_secret_recovery_window_in_days
      )
    )
    error_message = "application_secret_recovery_window_in_days must be null, 0, or a whole number from 7 through 30."
  }
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "CIDR blocks allowed to reach the public EKS API endpoint; restrict this to trusted addresses"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "node_instance_types" {
  description = "EC2 instance types used by the managed node group"
  type        = list(string)
  default     = ["t3.small"]
}

variable "node_capacity_type" {
  description = "Capacity type for the managed node group"
  type        = string
  default     = "ON_DEMAND"

  validation {
    condition     = contains(["ON_DEMAND", "SPOT"], var.node_capacity_type)
    error_message = "node_capacity_type must be ON_DEMAND or SPOT."
  }
}

variable "cloudwatch_log_retention_in_days" {
  description = "Retention period for EKS control-plane logs"
  type        = number
  default     = 30
}

variable "aws_load_balancer_controller_chart_version" {
  description = "Pinned Helm chart version for AWS Load Balancer Controller"
  type        = string
  default     = "1.14.0"
}

variable "external_secrets_chart_version" {
  description = "Pinned Helm chart version for External Secrets Operator"
  type        = string
  default     = "2.5.0"
}

variable "github_actions_oidc_subject" {
  description = "Exact GitHub OIDC subject allowed to deploy; null disables creation of the CI/CD role"
  type        = string
  default     = null
  nullable    = true
}

variable "github_oidc_provider_arn" {
  description = "Existing GitHub Actions OIDC provider ARN; null creates the account-level provider when CI/CD is enabled"
  type        = string
  default     = null
  nullable    = true
}
