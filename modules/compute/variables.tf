# modules/compute/variables.tf
variable "environment" {
  description = "Environment name"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "instance_subnet_ids" {
  description = "List of subnet IDs for EC2 instances"
  type        = list(string)
}

variable "alb_subnet_ids" {
  description = "List of public subnet IDs for the load balancer"
  type        = list(string)
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "aws_region" {
  description = "AWS region used by the instance bootstrap"
  type        = string
}

variable "db_host" {
  description = "Database host endpoint"
  type        = string
}

variable "db_port" {
  description = "Database port"
  type        = number
  default     = 5432
}

variable "db_name" {
  description = "Database name"
  type        = string
}

variable "db_username" {
  description = "Database username"
  type        = string
}

variable "db_password_ssm_parameter_name" {
  description = "Name of the SSM SecureString parameter holding the database password"
  type        = string
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
