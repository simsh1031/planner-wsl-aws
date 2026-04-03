# ─────────────────────────────────────────
# VPC
# ─────────────────────────────────────────
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# ─────────────────────────────────────────
# Internet Gateway
# ─────────────────────────────────────────
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# ─────────────────────────────────────────
# Public Subnets (NAT Gateway / ALB)
# ─────────────────────────────────────────
resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_a_cidr
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-a"
    Tier = "public"
  }
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_b_cidr
  availability_zone       = "${var.aws_region}c"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-b"
    Tier = "public"
  }
}

# ─────────────────────────────────────────
# Private Subnets – ECS Fargate
# ─────────────────────────────────────────
resource "aws_subnet" "private_ecs_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_ecs_a_cidr
  availability_zone = "${var.aws_region}a"

  tags = {
    Name = "${var.project_name}-private-ecs-a"
    Tier = "private-ecs"
  }
}

resource "aws_subnet" "private_ecs_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_ecs_b_cidr
  availability_zone = "${var.aws_region}c"

  tags = {
    Name = "${var.project_name}-private-ecs-b"
    Tier = "private-ecs"
  }
}

# ─────────────────────────────────────────
# Private Subnets – RDS
# ─────────────────────────────────────────
resource "aws_subnet" "private_rds_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_rds_a_cidr
  availability_zone = "${var.aws_region}a"

  tags = {
    Name = "${var.project_name}-private-rds-a"
    Tier = "private-rds"
  }
}

resource "aws_subnet" "private_rds_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_rds_b_cidr
  availability_zone = "${var.aws_region}c"

  tags = {
    Name = "${var.project_name}-private-rds-b"
    Tier = "private-rds"
  }
}

# ─────────────────────────────────────────
# Elastic IPs for NAT Gateways
# ─────────────────────────────────────────
resource "aws_eip" "nat_a" {
  domain = "vpc"
  tags = {
    Name = "${var.project_name}-nat-eip-a"
  }
}

resource "aws_eip" "nat_b" {
  domain = "vpc"
  tags = {
    Name = "${var.project_name}-nat-eip-b"
  }
}

# ─────────────────────────────────────────
# NAT Gateways (one per AZ)
# ─────────────────────────────────────────
resource "aws_nat_gateway" "nat_a" {
  allocation_id = aws_eip.nat_a.id
  subnet_id     = aws_subnet.public_a.id

  tags = {
    Name = "${var.project_name}-nat-a"
  }

  depends_on = [aws_internet_gateway.igw]
}

resource "aws_nat_gateway" "nat_b" {
  allocation_id = aws_eip.nat_b.id
  subnet_id     = aws_subnet.public_b.id

  tags = {
    Name = "${var.project_name}-nat-b"
  }

  depends_on = [aws_internet_gateway.igw]
}

# ─────────────────────────────────────────
# Route Tables
# ─────────────────────────────────────────

# Public route table → IGW
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.project_name}-rt-public"
  }
}

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

# Private route table AZ-a → NAT-a
resource "aws_route_table" "private_a" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_a.id
  }

  tags = {
    Name = "${var.project_name}-rt-private-a"
  }
}

resource "aws_route_table_association" "private_ecs_a" {
  subnet_id      = aws_subnet.private_ecs_a.id
  route_table_id = aws_route_table.private_a.id
}

resource "aws_route_table_association" "private_rds_a" {
  subnet_id      = aws_subnet.private_rds_a.id
  route_table_id = aws_route_table.private_a.id
}

# Private route table AZ-b → NAT-b
resource "aws_route_table" "private_b" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_b.id
  }

  tags = {
    Name = "${var.project_name}-rt-private-b"
  }
}

resource "aws_route_table_association" "private_ecs_b" {
  subnet_id      = aws_subnet.private_ecs_b.id
  route_table_id = aws_route_table.private_b.id
}

resource "aws_route_table_association" "private_rds_b" {
  subnet_id      = aws_subnet.private_rds_b.id
  route_table_id = aws_route_table.private_b.id
}
