output "alb_dns_name" {
  value = aws_lb.alb.dns_name
}

output "web1_public_ip" {
  value = aws_instance.web1.public_ip
}

output "web2_public_ip" {
  value = aws_instance.web2.public_ip
}

output "rds_master_endpoint" {
  value = aws_db_instance.master.endpoint
}

output "rds_slave_endpoint" {
  value = aws_db_instance.slave.endpoint
}
