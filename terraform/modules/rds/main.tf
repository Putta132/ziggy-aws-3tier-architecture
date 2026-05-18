variable "project_name"          { type = string }
variable "private_db_subnet_ids" { type = list(string) }
variable "db_sg_id"              { type = string }
variable "db_name"               { type = string }
variable "db_username"           { type = string }
variable "db_password"           { type = string; sensitive = true }

resource "aws_db_subnet_group" "this" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = var.private_db_subnet_ids
  tags       = { Name = "${var.project_name}-db-subnet-group" }
}

resource "aws_db_instance" "mysql" {
  identifier              = "${var.project_name}-mysql"
  engine                  = "mysql"
  engine_version          = "8.0"
  instance_class          = "db.t3.micro"
  allocated_storage       = 20
  storage_type            = "gp2"
  db_name                 = var.db_name
  username                = var.db_username
  password                = var.db_password
  db_subnet_group_name    = aws_db_subnet_group.this.name
  vpc_security_group_ids  = [var.db_sg_id]
  publicly_accessible     = false
  skip_final_snapshot     = true
  deletion_protection     = false
  multi_az                = true   # High availability across 2 AZs
  backup_retention_period = 7
  tags = { Name = "${var.project_name}-rds" }
}

output "db_endpoint" { value = aws_db_instance.mysql.address }
