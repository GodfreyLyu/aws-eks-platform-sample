variable "aws_region" {
  description = "AWS region where bootstrap resources are created"

  type = string

  default = "ap-northeast-1"
}


variable "project_name" {
  description = "Project name used for resource naming"

  type = string

  default = "aws-eks-platform"
}


variable "environment" {
  description = "Environment tag"

  type = string

  default = "bootstrap"
}