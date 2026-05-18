variable "project_name"           { type = string }
variable "vpc_id"                  { type = string }
variable "public_subnet_ids"       { type = list(string) }
variable "private_app_subnet_ids"  { type = list(string) }
variable "web_sg_id"               { type = string }
variable "app_sg_id"               { type = string }
variable "alb_sg_id"               { type = string }
variable "internal_alb_sg_id"      { type = string }

# ── External ALB (internet-facing) ────────────────────────────────────────────
resource "aws_lb" "external" {
  name               = "${var.project_name}-external-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_sg_id]
  subnets            = var.public_subnet_ids
  tags               = { Name = "${var.project_name}-external-alb" }
}

resource "aws_lb_target_group" "web" {
  name        = "${var.project_name}-web-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"
  health_check {
    path                = "/health"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
  tags = { Name = "${var.project_name}-web-tg" }
}

resource "aws_lb_listener" "external_http" {
  load_balancer_arn = aws_lb.external.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

# ── Internal ALB (app tier) ───────────────────────────────────────────────────
resource "aws_lb" "internal" {
  name               = "${var.project_name}-internal-alb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [var.internal_alb_sg_id]
  subnets            = var.private_app_subnet_ids
  tags               = { Name = "${var.project_name}-internal-alb" }
}

resource "aws_lb_target_group" "app" {
  name        = "${var.project_name}-app-tg"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"
  health_check {
    path                = "/health"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
  tags = { Name = "${var.project_name}-app-tg" }
}

resource "aws_lb_listener" "internal_http" {
  load_balancer_arn = aws_lb.internal.arn
  port              = 3000
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

output "external_alb_dns"  { value = aws_lb.external.dns_name }
output "internal_alb_dns"  { value = aws_lb.internal.dns_name }
output "external_tg_arn"   { value = aws_lb_target_group.web.arn }
output "internal_tg_arn"   { value = aws_lb_target_group.app.arn }
