########## Launch Template ##########

resource "aws_launch_template" "lt" {
  name                   = ""
  description = "custom aws_launch_template"
  image_id               = "ami-06dd92ecc74fdfb36"
  instance_type          = "t2.micro"
  key_name               = "sandbox-ssh-key"
  user_data = filebase64("${path.module}/httpd_install.sh")
  update_default_version = true

  iam_instance_profile {
    name = aws_iam_instance_profile.instance_profile.name
  }

  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_size = 16
      volume_type = "gp2"
    }
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups = [module.security-group_frontend.security_group_id]
  }

  tag_specifications {
    resource_type = "instance"

    tags = merge(
      local.common_tags,
      {
        Name = ""
      },
      {
        CreatedBy = "ASG"
      }
    )
  }

  depends_on = [ 
    module.security-group_frontend,
    aws_iam_instance_profile.instance_profile
   ]

  tags = merge(
    local.common_tags,
    {
      Name = ""
    }
  )
}

########## Auto Scaling Group ##########

resource "aws_autoscaling_group" "asg" {
  name                = ""
  launch_template {
    id      = aws_launch_template.lt.id
    version = aws_launch_template.lt.latest_version
  }
  
  health_check_grace_period = 300
  target_group_arns   = [aws_lb_target_group.lb_tg.arn]
  vpc_zone_identifier       = module.vpc.public_subnets[*]
  health_check_type         = "ELB"
  
  desired_capacity    = 1
  max_size            = 2
  min_size            = 1

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 80
    }
    triggers = []
  }
  
  tag {
    key                 = "Name"
    value               = ""
    propagate_at_launch = true
  }
}

########## Auto Scaling Group Policy ##########

resource "aws_autoscaling_policy" "asg_policy" {
  name                   = ""
  autoscaling_group_name = aws_autoscaling_group.asg.name
  policy_type               = "TargetTrackingScaling"
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 80
  }
}