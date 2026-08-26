variable "environment" {
  description = "Environment name"
  type        = string
}

variable "retention_days" {
  description = "Number of days to retain logs"
  type        = number
  default     = 30
}

variable "application_name" {
  description = "Name of the application"
  type        = string
  default     = "web-app"
}
