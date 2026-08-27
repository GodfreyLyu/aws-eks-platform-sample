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

variable "vpc_id" {
  description = "VPC ID for EKS"
  type        = string
}

variable "private_subnets" {
  description = "Private subnet IDs for EKS nodes"
  type        = list(string)
}

variable "endpoint_public_access_cidrs" {
  description = "CIDR blocks allowed to access the public Kubernetes API endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "node_instance_types" {
  description = "EC2 instance types for the managed node group"
  type        = list(string)
  default     = ["t3.small"]
}

variable "node_capacity_type" {
  description = "Managed node group capacity type"
  type        = string
  default     = "ON_DEMAND"
}

variable "cloudwatch_log_retention_in_days" {
  description = "Retention period for EKS control-plane logs"
  type        = number
  default     = 30
}

variable "access_entries" {
  description = "IAM principals and EKS access policies to add to the cluster"
  type = map(object({
    kubernetes_groups = optional(list(string))
    principal_arn     = string
    type              = optional(string, "STANDARD")
    user_name         = optional(string)
    tags              = optional(map(string), {})
    policy_associations = optional(map(object({
      policy_arn = string
      access_scope = object({
        namespaces = optional(list(string))
        type       = string
      })
    })), {})
  }))
  default = {}
}
