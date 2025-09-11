output "alb_dns_name" {
  description = "DNS name of the ALB"
  value       = aws_lb.web_alb.dns_name
}

output "rds_master_endpoint" {
  description = "Endpoint of the RDS master"
  value       = aws_db_instance.db_master.endpoint
}

output "rds_replica_endpoint" {
  description = "Endpoint of the RDS replica"
  value       = aws_db_instance.db_replica.endpoint
}

output "db_master_arn" {
  value = aws_db_instance.db_master.arn
}