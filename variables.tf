variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "key_name" {
  description = "Name of SSH key pair"
  type        = string
}

variable "database_config" {
  description = "Database configuration"
  type = object({
    instance_class    = string
    allocated_storage = number
    engine           = string
    engine_version   = string
    database_name    = string
    username         = string
    multi_az         = bool
  })
}

variable "database_password" {
  description = "Database master password"
  type        = string
  sensitive   = true
}

variable "asg_config" {
  description = "Auto Scaling Group configuration"
  type = object({
    min_size                  = number
    max_size                  = number
    desired_capacity          = number
    health_check_grace_period = number
    health_check_type         = string
    default_cooldown          = number
    protect_from_scale_in     = bool
  })
}

variable "log_retention_days" {
  description = "Number of days to retain logs in CloudWatch"
  type        = number
  default     = 30
}