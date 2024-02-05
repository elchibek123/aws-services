########## Application Load Balancer ##########

resource "aws_lb" "lb" {
  name               = ""
  internal           = false
  load_balancer_type = "application"
  security_groups    = [module.security-group_alb.security_group_id]
  subnets            = module.vpc.public_subnets[*]

  tags = merge(
    local.common_tags,
    {
      Name = ""
    }
  )
}

########## Target Group ##########

resource "aws_lb_target_group" "lb_tg" {
  name                          = ""
  port                          = 80
  protocol                      = "HTTP"
  vpc_id                        = module.vpc.vpc_id
  target_type = "instance"
  health_check {
    path    = "/index.html"
    port    = 80
    matcher = "200"
  }

  lifecycle {
    create_before_destroy = true
  }
}

########## Listener ##########

resource "aws_lb_listener" "https_listener" {
  load_balancer_arn = aws_lb.lb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.acm.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lb_tg.arn
  }

  depends_on = [aws_acm_certificate.acm]
}