# ─────────────────────────────────────────
# Security Group: ALB (sg-alb)
# ─────────────────────────────────────────
resource "aws_security_group" "alb" {
  name        = "${var.project_name}-sg-alb"
  description = "Allow HTTPS inbound from internet"
  vpc_id      = aws_vpc.main.id

  # ingress {
  #   description = "HTTPS from internet"
  #   from_port   = 443
  #   to_port     = 443
  #   protocol    = "tcp"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }

  ingress {
    description = "HTTP redirect"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-sg-alb"
  }
}

# ─────────────────────────────────────────
# Security Group: ECS Fargate (sg-ecs)
# ─────────────────────────────────────────
resource "aws_security_group" "ecs" {
  name        = "${var.project_name}-sg-ecs"
  description = "Allow traffic from ALB on app port"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Backend port from ALB"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  ingress {
    description     = "Frontend port from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-sg-ecs"
  }
}

# ─────────────────────────────────────────
# Security Group: RDS MySQL (sg-rds)
# ─────────────────────────────────────────
resource "aws_security_group" "rds" {
  name        = "${var.project_name}-sg-rds"
  description = "Allow MySQL from ECS tasks only"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "MySQL from ECS"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-sg-rds"
  }
}
