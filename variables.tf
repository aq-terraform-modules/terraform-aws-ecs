variable "name" {
  description = "Name of the cluster"
}

variable "capacity_providers" {
  description = "Capacity providers"
  default = "FARGATE"
}

variable "enable_container_insights" {
  description = "Enable container insights or not"
  default = "enabled"
}