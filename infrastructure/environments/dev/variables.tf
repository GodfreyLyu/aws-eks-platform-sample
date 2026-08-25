variable "aws_region" {
  description = "region of the eks cluster"
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
