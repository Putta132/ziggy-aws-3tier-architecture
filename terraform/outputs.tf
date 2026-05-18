output "external_alb_dns" {
  description = "DNS name of the external ALB — open this in your browser"
  value       = module.alb.external_alb_dns
}

output "internal_alb_dns" {
  description = "DNS name of the internal ALB (app tier)"
  value       = module.alb.internal_alb_dns
}

output "rds_endpoint" {
  description = "RDS MySQL endpoint (private — accessible only from app tier)"
  value       = module.rds.db_endpoint
  sensitive   = true
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}
