resource "aws_autoscaling_group" "odoo-autoscaling-group" {
  name                 = "odoo-autoscaling-group"
  max_size             = var.max_instance_size
  min_size             = var.min_instance_size
  desired_capacity     = var.desired_capacity
  vpc_zone_identifier  = [aws_subnet.web-subnet-1.id, aws_subnet.web-subnet-2.id]
  launch_configuration = aws_launch_configuration.ecs-launch-configuration.name
  health_check_type    = "ELB"
}