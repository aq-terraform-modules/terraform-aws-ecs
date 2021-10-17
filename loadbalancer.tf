#################################################################################
# LOADBALANCER RELATED
#################################################################################
resource "aws_lb_target_group" "target_group" {
  name        = local.frontend_name
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id
}


resource "aws_lb_listener_rule" "rule" {
  listener_arn = var.listener_arn
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group.arn
  }

  condition {
    host_header {
      values = ["${var.frontend_domain}.${var.parent_domain}"]
    }
  }
}