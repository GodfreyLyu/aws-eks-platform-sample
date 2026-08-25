terraform {
  backend "s3" {
    bucket       = "aws-eks-platform-terraform-state"
    key          = "eks/dev/terraform.tfstate"
    region       = "ap-northeast-1"
    use_lockfile = true
    encrypt      = true
  }
}