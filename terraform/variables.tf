variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Project name prefix for all resources"
  type        = string
  default     = "ziggy"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of AZs to use"
  type        = list(string)
  default     = ["ap-south-1a", "ap-south-1b"]
}

variable "public_subnet_cidrs" {
  description = "CIDRs for public subnets (web tier)"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_app_cidrs" {
  description = "CIDRs for private subnets (app tier)"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "private_db_cidrs" {
  description = "CIDRs for private subnets (database tier)"
  type        = list(string)
  default     = ["10.0.21.0/24", "10.0.22.0/24"]
}

variable "ami_id" {
  description = "Ubuntu 22.04 LTS AMI ID (region-specific)"
  type        = string
  default     = "ami-0f5ee92e2d63afc18" # Ubuntu 22.04 ap-south-1
}

variable "web_instance_type" {
  description = "EC2 instance type for web tier"
  type        = string
  default     = "t3.micro"
}

variable "app_instance_type" {
  description = "EC2 instance type for app tier"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "EC2 key pair name for SSH access"
  type        = string
}

variable "db_name" {
  description = "RDS database name"
  type        = string
  default     = "ziggydb"
}

variable "db_username" {
  description = "RDS master username"
  type        = string
  default     = "ziggy_admin"
}

variable "db_password" {
  description = "RDS master password (use terraform.tfvars — never hardcode)"
  type        = string
  sensitive   = true
}
