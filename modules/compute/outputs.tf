output "app_security_group_id" {
  description = "ID of the application security group"
  value       = aws_security_group.web.id
}

output "alb_dns_name" {
  description = "The DNS name of the load balancer"
  value       = aws_lb.web.dns_name
}

output "alb_security_group_id" {
  description = "ID of the ALB security group"
  value       = aws_security_group.alb.id
}