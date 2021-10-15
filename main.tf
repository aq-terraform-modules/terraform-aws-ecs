resource "aws_ecs_cluster" "cluster" {
  name = var.name
  capacity_providers = var.capacity_providers
  setting {
    name = containerInsights
    value = var.enable_container_insights
  }
}