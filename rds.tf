# ─────────────────────────────────────────
# RDS Subnet Group
# ─────────────────────────────────────────
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-rds-subnet-group"
  subnet_ids = [aws_subnet.private_rds_a.id, aws_subnet.private_rds_b.id]

  tags = {
    Name = "${var.project_name}-rds-subnet-group"
  }
}

# ─────────────────────────────────────────
# RDS MySQL – Multi-AZ (Primary + Standby)
# ─────────────────────────────────────────
resource "aws_db_instance" "primary" {
  identifier        = "${var.project_name}-mysql"
  engine            = "mysql"
  engine_version    = "8.0"
  instance_class    = var.db_instance_class
  allocated_storage = 20
  storage_type      = "gp3"
  storage_encrypted = true

  db_name  = var.db_name
  username = var.db_username
  password = random_password.db_password.result

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  # Multi-AZ → creates synchronous standby in AZ-b automatically
  multi_az = true

  # Backup
  backup_retention_period = 1
  backup_window           = "03:00-04:00"
  maintenance_window      = "mon:04:30-mon:05:30"

  # Monitoring
  monitoring_interval             = 60
  monitoring_role_arn             = aws_iam_role.rds_monitoring.arn
  performance_insights_enabled    = false
  enabled_cloudwatch_logs_exports = ["error", "general", "slowquery"]

  auto_minor_version_upgrade = true
  deletion_protection        = false
  skip_final_snapshot        = true
  final_snapshot_identifier  = "${var.project_name}-final-snapshot"

  tags = {
    Name = "${var.project_name}-rds-primary"
  }
}

# ─────────────────────────────────────────
# IAM – RDS Enhanced Monitoring Role
# ─────────────────────────────────────────
resource "aws_iam_role" "rds_monitoring" {
  name = "${var.project_name}-rds-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# ─────────────────────────────────────────
# Random password for RDS
# ─────────────────────────────────────────
resource "random_password" "db_password" {
  length           = 20
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# ─────────────────────────────────────────
# Secrets Manager
# ─────────────────────────────────────────
# resource "aws_secretsmanager_secret" "db_password" {
#   name = "${var.project_name}/db/password"
# }

# resource "aws_secretsmanager_secret_version" "db_password" {
#   secret_id = aws_secretsmanager_secret.db_password.id

#   secret_string = jsonencode({
#     DB_PASSWORD = random_password.db_password.result
#   })
# }