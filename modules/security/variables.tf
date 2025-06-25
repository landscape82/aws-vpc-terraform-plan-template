variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "database_security_group_id" {
  description = "Security group ID of the RDS instance"
  type        = string
}