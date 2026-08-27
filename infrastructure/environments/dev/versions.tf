terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.59.0, < 7.0"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.1"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.38"
    }
  }

  required_version = ">= 1.10, < 2.0"
}
