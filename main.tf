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
resource "aws_cloudwatch_log_group" "monitoring" {
  name = var.name
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
          "awslogs-group": "${var.name}", 
          "awslogs-region": "${var.region}", 
          "awslogs-stream-prefix": "ecs-frontend" 
        }
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
    aws_cloudwatch_log_group.monitoring
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
}

#################################################################################
# CODEPIPELINE
#################################################################################
resource "aws_codecommit_repository" "monitoring" {
  repository_name = var.name
  description     = "Repository for saving task-definition.json that will be used for CodePipeline"
  default_branch  = "main"
}

resource "local_file" "image_definition" {
  content = templatefile(
    "${path.module}/templates/frontend-image-definition.json",
    {
      frontend_image = var.frontend_image
      frontend_name = local.frontend_name
    }
  )
  filename = "./frontend-image-definition.json"
}

resource "null_resource" "frontend_push_json" {
  provisioner "local-exec" {
    command = <<-EOT
      aws codecommit put-file --region ${var.region} --repository-name ${var.name} --branch-name main --file-content file://frontend-image-definition.json --file-path frontend-image-definition.json --name 'Terraform Deployment' --email 'sheid1309@gmail.com' --commit-message 'Init commit'
    EOT
  }

  depends_on = [
    local_file.image_definition
  ]
}
