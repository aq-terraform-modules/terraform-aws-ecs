variable "name" {
  description = "Name of the cluster"
}

variable "capacity_providers" {
  description = "Capacity providers"
  default     = "FARGATE"
}

variable "enable_container_insights" {
  description = "Enable container insights or not"
  default     = "enabled"
}

variable "frontend_cpu" {
  description = "CPU for frontend container"
}

variable "frontend_memory" {
  description = "Memory for frontend container"
}

variable "requires_compatibilities" {
  description = "Task compatibilities"
  default = "FARGATE"
}

variable "network_mode" {
  description = "Network mode for container and task definition"
  default = "awsvpc"
}

variable "frontend_image" {
  description = "Frontend image to create container"
}

variable "frontend_port" {
  description = "Container frontend port"
}

variable "frontend_domain" {
  description = "Domain used for the frontend service"
}

variable "force_new_deployment" {
  description = "Force new deployment when task definition get update"
  type = bool
  default = true
}

variable "desired_count" {
  description = "Desired count to create the number of task inside the service"
  default = 1
}

variable "launch_type" {
  description = "Service launch type"
  default = "FARGATE"
}

variable "subnets" {
  description = "Subnet of the service"
}

variable "assign_public_ip" {
  description = "Assign public ip to service or not"
  type = bool
  default = true
}

variable "vpc_id" {
  description = "VPC ID that will associate with the LB target group"
}

variable "listener_arn" {
  description = "LB listener ARN"
}

variable "lb_dns_name" {
  description = "LB dns name to create the alias in route53"
}

variable "lb_zone_id" {
  description = "Availability Zone of the LB"
}

variable "route53_zone_id" {
  description = "Route53 id to create record for the service"
}

variable "evaluate_target_health" {
  description = "Evaluate health of the target in the route53 alias setting"
  type = bool
  default = true
}