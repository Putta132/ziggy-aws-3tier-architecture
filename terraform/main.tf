terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# ── VPC ──────────────────────────────────────────────────────────────────────
module "vpc" {
  source             = "./modules/vpc"
  project_name       = var.project_name
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_app_cidrs    = var.private_app_cidrs
  private_db_cidrs     = var.private_db_cidrs
}

# ── SECURITY GROUPS ──────────────────────────────────────────────────────────
module "security_groups" {
  source       = "./modules/security_groups"
  project_name = var.project_name
  vpc_id       = module.vpc.vpc_id
}

# ── APPLICATION LOAD BALANCERS ───────────────────────────────────────────────
module "alb" {
  source              = "./modules/alb"
  project_name        = var.project_name
  vpc_id              = module.vpc.vpc_id
  public_subnet_ids   = module.vpc.public_subnet_ids
  private_app_subnet_ids = module.vpc.private_app_subnet_ids
  web_sg_id           = module.security_groups.web_sg_id
  app_sg_id           = module.security_groups.app_sg_id
  alb_sg_id           = module.security_groups.alb_sg_id
  internal_alb_sg_id  = module.security_groups.internal_alb_sg_id
}

# ── RDS (DATABASE TIER) ──────────────────────────────────────────────────────
module "rds" {
  source             = "./modules/rds"
  project_name       = var.project_name
  private_db_subnet_ids = module.vpc.private_db_subnet_ids
  db_sg_id           = module.security_groups.db_sg_id
  db_name            = var.db_name
  db_username        = var.db_username
  db_password        = var.db_password
}

# ── EC2 — WEB TIER ───────────────────────────────────────────────────────────
module "web_tier" {
  source             = "./modules/ec2"
  project_name       = var.project_name
  tier               = "web"
  subnet_ids         = module.vpc.public_subnet_ids
  sg_id              = module.security_groups.web_sg_id
  target_group_arn   = module.alb.external_tg_arn
  ami_id             = var.ami_id
  instance_type      = var.web_instance_type
  key_name           = var.key_name
  min_size           = 1
  max_size           = 3
  desired_capacity   = 2
  user_data = base64encode(templatefile("${path.module}/scripts/web-tier-setup.sh", {
    INTERNAL_ALB_DNS = module.alb.internal_alb_dns
  }))
}

# ── EC2 — APP TIER ───────────────────────────────────────────────────────────
module "app_tier" {
  source             = "./modules/ec2"
  project_name       = var.project_name
  tier               = "app"
  subnet_ids         = module.vpc.private_app_subnet_ids
  sg_id              = module.security_groups.app_sg_id
  target_group_arn   = module.alb.internal_tg_arn
  ami_id             = var.ami_id
  instance_type      = var.app_instance_type
  key_name           = var.key_name
  min_size           = 1
  max_size           = 3
  desired_capacity   = 2
  user_data = base64encode(templatefile("${path.module}/scripts/app-tier-setup.sh", {
    DB_HOST     = module.rds.db_endpoint
    DB_USER     = var.db_username
    DB_PASSWORD = var.db_password
  }))
}
