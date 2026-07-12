# --- Standard RDS outputs ---

output "rds_endpoint" {
  description = "Connection endpoint for the standard RDS instance"
  value       = var.use_aurora ? null : aws_db_instance.standard[0].endpoint
}

output "rds_address" {
  description = "Hostname of the standard RDS instance (without port)"
  value       = var.use_aurora ? null : aws_db_instance.standard[0].address
}

output "rds_port" {
  description = "Port of the standard RDS instance"
  value       = var.use_aurora ? null : aws_db_instance.standard[0].port
}

# --- Aurora outputs ---

output "aurora_cluster_endpoint" {
  description = "Writer endpoint of the Aurora cluster"
  value       = var.use_aurora ? aws_rds_cluster.aurora[0].endpoint : null
}

output "aurora_reader_endpoint" {
  description = "Reader endpoint of the Aurora cluster"
  value       = var.use_aurora ? aws_rds_cluster.aurora[0].reader_endpoint : null
}

output "aurora_port" {
  description = "Port of the Aurora cluster"
  value       = var.use_aurora ? aws_rds_cluster.aurora[0].port : null
}

# --- Shared outputs ---

output "endpoint" {
  description = "Primary database endpoint (works for both RDS and Aurora)"
  value       = var.use_aurora ? aws_rds_cluster.aurora[0].endpoint : aws_db_instance.standard[0].endpoint
}

output "port" {
  description = "Database port (works for both RDS and Aurora)"
  value       = var.use_aurora ? aws_rds_cluster.aurora[0].port : aws_db_instance.standard[0].port
}

output "security_group_id" {
  description = "ID of the security group assigned to RDS / Aurora"
  value       = aws_security_group.rds.id
}

output "db_subnet_group_name" {
  description = "Name of the DB subnet group"
  value       = aws_db_subnet_group.default.name
}
