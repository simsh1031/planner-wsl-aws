# ─────────────────────────────────────────
# Secrets Manager – DB Password
# ─────────────────────────────────────────
# resource "aws_secretsmanager_secret" "db_password" {
#   name                    = "${var.project_name}/db/password"
#   recovery_window_in_days = 7

#   tags = {
#     Name = "${var.project_name}-db-password"
#   }
# }

# resource "aws_secretsmanager_secret_version" "db_password" {
#   secret_id     = aws_secretsmanager_secret.db_password.id
#   secret_string = random_password.db_password.result
# }

# secrets.tf — 최종 상태
resource "aws_secretsmanager_secret" "db_password" {
  name                    = "${var.project_name}/db/password"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = jsonencode({
    DB_PASSWORD = random_password.db_password.result
  })
}

# ─────────────────────────────────────────
# Secrets Manager – JWT Secret
# ─────────────────────────────────────────
resource "random_password" "jwt_secret" {
  length  = 64
  special = false
}

resource "aws_secretsmanager_secret" "jwt_secret" {
  name                    = "${var.project_name}/jwt/secret"
  recovery_window_in_days = 7

  tags = {
    Name = "${var.project_name}-jwt-secret"
  }
}

resource "aws_secretsmanager_secret_version" "jwt_secret" {
  secret_id     = aws_secretsmanager_secret.jwt_secret.id
  secret_string = random_password.jwt_secret.result
}
