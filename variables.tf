variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-2"
}

variable "project_name" {
  description = "Project name used as prefix for all resources"
  type        = string
  default     = "myapp"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "192.168.0.0/16"
}

# Subnets
variable "public_subnet_a_cidr" {
  description = "Public subnet A (AZ-a) CIDR – NAT Gateway"
  type        = string
  default     = "192.168.1.0/24"
}

variable "public_subnet_b_cidr" {
  description = "Public subnet B (AZ-b) CIDR – NAT Gateway"
  type        = string
  default     = "192.168.2.0/24"
}

variable "private_ecs_a_cidr" {
  description = "Private subnet A (AZ-a) CIDR – ECS Fargate"
  type        = string
  default     = "192.168.3.0/24"
}

variable "private_ecs_b_cidr" {
  description = "Private subnet B (AZ-b) CIDR – ECS Fargate"
  type        = string
  default     = "192.168.4.0/24"
}

variable "private_rds_a_cidr" {
  description = "Private subnet A (AZ-a) CIDR – RDS Primary"
  type        = string
  default     = "192.168.5.0/24"
}

variable "private_rds_b_cidr" {
  description = "Private subnet B (AZ-b) CIDR – RDS Standby"
  type        = string
  default     = "192.168.6.0/24"
}

# ECS / App
variable "app_port" {
  description = "Application container port"
  type        = number
  default     = 8080
}

variable "ecs_cpu" {
  description = "ECS Task CPU units"
  type        = number
  default     = 512
}

variable "ecs_memory" {
  description = "ECS Task memory (MiB)"
  type        = number
  default     = 1024
}

variable "ecs_desired_count" {
  description = "Desired number of ECS tasks"
  type        = number
  default     = 2
}

variable "ecr_image_uri" {
  description = "Full ECR image URI (e.g. 123456789.dkr.ecr.ap-northeast-2.amazonaws.com/myapp:latest)"
  type        = string
  default     = "665565853585.dkr.ecr.ap-northeast-2.amazonaws.com/myapp:latest"
}

# RDS
variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_name" {
  description = "Initial database name"
  type        = string
  default     = "appdb"
}

variable "db_username" {
  description = "RDS master username"
  type        = string
  default     = "admin"
}

# ACM / Domain
variable "domain_name" {
  description = "Route53 domain name (e.g. example.com)"
  type        = string
  default     = "example.com"
}

variable "acm_certificate_arn" {
  description = "ACM certificate ARN for HTTPS listener"
  type        = string
  default     = "REPLACE_ME"
}

variable "frontend_image_uri" {
  type = string
}

variable "backend_image_uri" {
  type = string
}