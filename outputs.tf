output "database_identifier" {
  description = "Identificador da instância RDS."
  value       = aws_db_instance.main.identifier
}

output "database_endpoint" {
  description = "Hostname do RDS sem credenciais."
  value       = aws_db_instance.main.address
}

output "database_port" {
  description = "Porta do PostgreSQL."
  value       = aws_db_instance.main.port
}

output "database_name" {
  description = "Nome do banco inicial."
  value       = var.db_name
}

output "database_security_group_id" {
  description = "Security group do RDS para integrações futuras."
  value       = aws_security_group.database.id
}

output "jdbc_url" {
  description = "URL JDBC sem usuário ou senha."
  value       = "jdbc:postgresql://${aws_db_instance.main.address}:${aws_db_instance.main.port}/${var.db_name}"
}
