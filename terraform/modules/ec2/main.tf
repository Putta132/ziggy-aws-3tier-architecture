variable "project_name"      { type = string }
variable "tier"              { type = string }
variable "subnet_ids"        { type = list(string) }
variable "sg_id"             { type = string }
variable "target_group_arn"  { type = string }
variable "ami_id"            { type = string }
variable "instance_type"     { type = string }
variable "key_name"          { type = string }
variable "user_data"         { type = string }
variable "min_size"          { type = number }
variable "max_size"          { type = number }
variable "desired_capacity"  { type = number }

resource "aws_launch_template" "this" {
  name_prefix   = "${var.project_name}-${var.tier}-lt-"
  image_id      = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name

  network_interfaces {
    security_groups             = [var.sg_id]
    associate_public_ip_address = var.tier == "web" ? true : false
  }

  user_data = var.user_data

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name    = "${var.project_name}-${var.tier}-instance"
      Tier    = var.tier
      Project = var.project_name
    }
  }
}

resource "aws_autoscaling_group" "this" {
  name                = "${var.project_name}-${var.tier}-asg"
  vpc_zone_identifier = var.subnet_ids
  min_size            = var.min_size
  max_size            = var.max_size
  desired_capacity    = var.desired_capacity
  target_group_arns   = [var.target_group_arn]
  health_check_type   = "ELB"
  health_check_grace_period = 120

  launch_template {
    id      = aws_launch_template.this.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-${var.tier}-asg"
    propagate_at_launch = true
  }
}

# Scale out when CPU > 70%
resource "aws_autoscaling_policy" "scale_out" {
  name                   = "${var.project_name}-${var.tier}-scale-out"
  autoscaling_group_name = aws_autoscaling_group.this.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = 1
  cooldown               = 300
}

resource "aws_autoscaling_policy" "scale_in" {
  name                   = "${var.project_name}-${var.tier}-scale-in"
  autoscaling_group_name = aws_autoscaling_group.this.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = -1
  cooldown               = 300
}
