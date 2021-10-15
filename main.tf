locals {
  frontend_name = "${var.name}-frontend"
}
#################################################################################
# DATASOURCE
#################################################################################
data "aws_lb" "core_lb" {
  name = var.lb_name
}

data "aws_route53_zone" "main_zone" {
  name = var.main_domain
}

data "aws_vpc" "core_vpc" {
  filter {
    Name = var.vpc_name
  }
}

data "aws_subnet_ids" "public_subnets" {
  vpc_id = data.aws_vpc.core_vpc.id

  filter {
    Name = "*public*"
  }
}

#################################################################################
# CLUSTER CREATION
#################################################################################
resource "aws_ecs_cluster" "cluster" {
  name               = var.name
  capacity_providers = var.capacity_providers
  setting {
    name  = containerInsights
    value = var.enable_container_insights
  }
}

#################################################################################
# SERVICE & TASK DEFINITION CREATION
#################################################################################
resource "aws_ecs_task_definition" "task" {
  family = "${local.frontend_name}"
  cpu = var.frontend_cpu
  memory = var.frontend_memory
  requires_compatibilities = var.requires_compatibilities
  network_mode = var.network_mode
  container_definitions = <<TASK_DEFINITION
  [
    {
      "cpu": ${var.frontend_cpu},
      "memory": ${var.frontend_memory},
      "name": "${local.frontend_name}",
      "image": "${var.frontend_image}",
      "networkMode": "${var.network_mode}",
      "portMappings": [
        {
          "containerPort": ${var.frontend_port},
          "hostPort": ${var.frontend_port}
        }
      ]
    }
  ]
  TASK_DEFINITION
}

resource "aws_ecs_service" "service" {
  name = "${local.frontend_name}"
  cluster = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.task.arn
  force_new_deployment = var.force_new_deployment
  desired_count = var.desired_count
  launch_type = var.launch_type

  deployment_circuit_breaker {
    enabled = true
    rollback = true
  }

  network_configuration {
    subnets = data.aws_subnet_ids.public_subnets.ids
    assign_public_ip = var.assign_public_ip
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.target_group.arn
    container_name = local.frontend_name
    container_port = var.frontend_port
  }

  # Ignore change when task definition was updated
  lifecycle {
    ignore_changes = [
      task_definition
    ]
  }
}

#################################################################################
# LOADBALANCER RELATED
#################################################################################
resource "aws_lb_target_group" "target_group" {
  name = local.frontend_name
  port = 80
  protocol = "HTTP"
  target_type = "ip"
  vpc_id = data.aws_vpc.core_vpc.id
}

resource "aws_lb_listener_rule" "rule" {
  listener_arn = var.listener_arn
  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.target_group.arn
  }

  condition {
    host_header {
      values = var.frontend_domain
    }
  }
}

#################################################################################
# ROUTE53
#################################################################################
resource "aws_route53_record" "record" {
  zone_id = data.aws_route53_zone.main_zone.zone_id
  name = var.frontend_domain
  type = "A"
  alias {
    name = data.aws_lb.core_lb.dns_name
    zone_id = data.aws_lb.core_lb.zone_id
    evaluate_target_health = var.evaluate_target_health
  }
}