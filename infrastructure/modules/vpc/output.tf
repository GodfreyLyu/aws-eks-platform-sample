output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}


output "vpc_cidr_block" {
  description = "VPC CIDR"
  value       = module.vpc.vpc_cidr_block
}


output "private_subnets" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnets
}


output "public_subnets" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnets
}


output "availability_zones" {
  description = "Availability Zones"
  value       = module.vpc.azs
}


output "nat_gateway_ids" {
  description = "NAT Gateway IDs"
  value       = module.vpc.natgw_ids
}