variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "eks-workshop"
}

variable "cluster_version" {
  description = "EKS cluster version."
  type        = string
  default     = "1.33"
}

variable "vpc_id" {

  description = "VPC ID for EKS"

  type = string

}


variable "private_subnets" {

  description = "Private subnet IDs for EKS nodes"

  type = list(string)

}
