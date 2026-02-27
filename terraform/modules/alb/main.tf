# Application Load Balancer for Blue-Green
resource "aws_lb" "todo_alb" {
  name               = "todo-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = var.security_group_ids
  subnets           = var.subnet_ids

  enable_deletion_protection = false

  tags = {
    Environment = var.environment
    Project     = "todo-api-blue-green"
  }
}

# HTTPS Listener
resource "aws_lb_listener" "todo_https" {
  load_balancer_arn = aws_lb.todo_alb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = var.active_target_group_arn
  }
}

# Blue Target Group
resource "aws_lb_target_group" "todo_blue" {
  name     = "todo-blue-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    path               = "/health"
    matcher            = "200"
  }

  tags = {
    Environment = "blue"
  }
}

# Green Target Group
resource "aws_lb_target_group" "todo_green" {
  name     = "todo-green-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    path               = "/health"
    matcher            = "200"
  }

  tags = {
    Environment = "green"
  }
}

# Blue Target Group Attachment
resource "aws_lb_target_group_attachment" "blue" {
  target_group_arn = aws_lb_target_group.todo_blue.arn
  target_id        = var.blue_instance_id
  port             = 80
}

# Green Target Group Attachment
resource "aws_lb_target_group_attachment" "green" {
  target_group_arn = aws_lb_target_group.todo_green.arn
  target_id        = var.green_instance_id
  port             = 80
}

# Outputs
output "alb_dns_name" {
  value = aws_lb.todo_alb.dns_name
}

output "blue_target_group_arn" {
  value = aws_lb_target_group.todo_blue.arn
}

output "green_target_group_arn" {
  value = aws_lb_target_group.todo_green.arn
}
