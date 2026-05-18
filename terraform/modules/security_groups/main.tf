variable "project_name" { type = string }
variable "vpc_id"       { type = string }

# External ALB SG — accepts HTTP from anywhere
resource "aws_security_group" "alb" {
  name   = "${var.project_name}-alb-sg"
  vpc_id = var.vpc_id
  ingress {
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
  tags = { Name = "${var.project_name}-alb-sg" }
}

# Web tier EC2 SG — HTTP only from external ALB
resource "aws_security_group" "web" {
  name   = "${var.project_name}-web-sg"
  vpc_id = var.vpc_id
  ingress {
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
  tags = { Name = "${var.project_name}-web-sg" }
}

# Internal ALB SG — accepts traffic from web tier
resource "aws_security_group" "internal_alb" {
  name   = "${var.project_name}-internal-alb-sg"
  vpc_id = var.vpc_id
  ingress {
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "${var.project_name}-internal-alb-sg" }
}

# App tier EC2 SG — port 3000 only from internal ALB
resource "aws_security_group" "app" {
  name   = "${var.project_name}-app-sg"
  vpc_id = var.vpc_id
  ingress {
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.internal_alb.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "${var.project_name}-app-sg" }
}

# DB SG — MySQL port only from app tier
resource "aws_security_group" "db" {
  name   = "${var.project_name}-db-sg"
  vpc_id = var.vpc_id
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "${var.project_name}-db-sg" }
}

output "alb_sg_id"          { value = aws_security_group.alb.id }
output "web_sg_id"          { value = aws_security_group.web.id }
output "internal_alb_sg_id" { value = aws_security_group.internal_alb.id }
output "app_sg_id"          { value = aws_security_group.app.id }
output "db_sg_id"           { value = aws_security_group.db.id }
