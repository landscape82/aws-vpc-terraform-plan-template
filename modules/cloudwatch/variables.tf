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

resource "aws_cloudwatch_log_group" "app_logs" {
  name              = "/${var.environment}/${var.application_name}/logs"
  retention_in_days = var.retention_days

  tags = {
    Environment = var.environment
    Application = var.application_name
  }
}

# Metric filter
resource "aws_cloudwatch_log_metric_filter" "error_metric" {
  name           = "${var.environment}-${var.application_name}-errors"
  pattern        = "ERROR"
  log_group_name = aws_cloudwatch_log_group.app_logs.name

  metric_transformation {
    name          = "${var.environment}_${var.application_name}_error_count"
    namespace     = "${var.environment}/${var.application_name}/metrics"
    value         = "1"
    default_value = "0"
  }
}

# Alert from metrics thresholds
resource "aws_cloudwatch_metric_alarm" "error_alarm" {
  alarm_name          = "${var.environment}-${var.application_name}-high-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "${var.environment}_${var.application_name}_error_count"
  namespace           = "${var.environment}/${var.application_name}/metrics"
  period             = "300"
  statistic          = "Sum"
  threshold          = "10"
  alarm_description  = "This metric monitors error count in application logs"

  tags = {
    Environment = var.environment
    Application = var.application_name
  }
}