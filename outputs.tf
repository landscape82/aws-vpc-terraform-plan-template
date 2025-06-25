# ID of VPC provisioned by plan
output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.networking.vpc_id
}

# Public Subnets ID's
output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = module.networking.public_subnet_ids
}

# Private Subnets ID's
output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = module.networking.private_subnet_ids
}

# DNS for Application Load Balancer (handling docker application)
output "alb_dns_name" {
  description = "The DNS name of the load balancer"
  value       = module.compute.alb_dns_name
}

# RDS endpoint with port
output "database_endpoint" {
  description = "The database connection endpoint"
  value       = module.database.db_instance_endpoint
}