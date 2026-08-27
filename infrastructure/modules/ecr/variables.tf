variable "repository_name" {
  description = "Name of the ECR repository"
  type        = string
}

variable "force_delete" {
  description = "Allow Terraform to delete the repository even when it contains images"
  type        = bool
  default     = false
}

variable "max_image_count" {
  description = "Number of tagged images to retain"
  type        = number
  default     = 30
}

variable "untagged_image_retention_days" {
  description = "Days to retain untagged images"
  type        = number
  default     = 7
}

variable "tags" {
  description = "Tags applied to ECR resources"
  type        = map(string)
  default     = {}
}
