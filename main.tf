locals {
  frontend_name = "${var.name}-frontend"
}

#################################################################################
# CLUSTER CREATION
#################################################################################
resource "aws_ecs_cluster" "cluster" {
  name               = var.name
  capacity_providers = [var.capacity_providers]
  setting {
    name  = "containerInsights"
    value = var.enable_container_insights
  }
}

#################################################################################
# ECS RELATED
#################################################################################'
resource "aws_cloudwatch_log_group" "frontend" {
  name_prefix = var.frontend_log_group_name_prefix
}

resource "aws_ecs_task_definition" "task" {
  family                   = local.frontend_name
  cpu                      = var.frontend_cpu
  memory                   = var.frontend_memory
  requires_compatibilities = [var.requires_compatibilities]
  network_mode             = var.network_mode
  execution_role_arn       = aws_iam_role.ecs_tasks_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_tasks_execution_role.arn
  container_definitions    = <<TASK_DEFINITION
  [
    {
      "cpu": ${var.frontend_cpu},
      "memory": ${var.frontend_memory},
      "name": "${local.frontend_name}",
      "image": "${var.frontend_image}",
      "networkMode": "${var.network_mode}",
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "${var.frontend_log_group_name_prefix}", 
          "awslogs-region": "${var.region}", 
          "awslogs-stream-prefix": "ecs" 
      },
      "portMappings": [
        {
          "containerPort": ${var.frontend_port},
          "hostPort": ${var.frontend_port}
        }
      ]
    }
  ]
  TASK_DEFINITION

  depends_on = [
    aws_cloudwatch_log_group.frontend
  ]
}

resource "aws_ecs_service" "service" {
  name                 = local.frontend_name
  cluster              = aws_ecs_cluster.cluster.id
  task_definition      = aws_ecs_task_definition.task.arn
  force_new_deployment = var.force_new_deployment
  desired_count        = var.desired_count
  launch_type          = var.launch_type

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  network_configuration {
    subnets          = var.subnets
    assign_public_ip = var.assign_public_ip
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.target_group.arn
    container_name   = local.frontend_name
    container_port   = var.frontend_port
  }

  # Ignore change when task definition was updated
  # lifecycle {
  #   ignore_changes = [
  #     task_definition
  #   ]
  # }
}

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

#################################################################################
# ROUTE53
#################################################################################
resource "aws_route53_record" "record" {
  zone_id = var.route53_zone_id
  name    = var.frontend_domain
  type    = "A"
  alias {
    name                   = var.lb_dns_name
    zone_id                = var.lb_zone_id
    evaluate_target_health = var.evaluate_target_health
  }
}

#################################################################################
# CODEPIPELINE
#################################################################################
resource "aws_codecommit_repository" "monitoring" {
  repository_name = var.name
  description     = "Repository for saving task-definition.json that will be used for CodePipeline"
  default_branch  = "main"
}

