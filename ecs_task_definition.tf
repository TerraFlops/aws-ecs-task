variable "application_name" {
  type = string
  description = "Application name that is prefixed onto resource names"
}

locals {
  application_name_snake = join("", [for element in split("-", lower(replace(var.application_name, "_", "-"))) : title(element)])
}

variable "ecs_task_secrets" {
  description = "Optional map of secrets to pass into the task definition"
  type = map(string)
  default = {}
}

variable "ecs_task_definition_template_parameter_prefix" {
  description = "Prefix prepended to the SSM parameter which stores the task definition container template (include trailing slash if you are specify a root path)"
  type = string
  default = "/Terraform/ECS/Template/"
}

variable "ecs_task_definition_template_tag" {
  description = "The string to be used in the ECS template for the image tag. Defaults to 'DEPLOYMENT_IMAGE_TAG'"
  type = string
  default = "DEPLOYMENT_IMAGE_TAG"
}

variable "ecs_task_family" {
  description = "Optional override for the container family. If none supplied the container name will be used as the family"
  type = string
  default = null
}

variable "ecs_task_tags" {
  type = map(string)
  default = {}
}
variable "ecs_task_pid_mode" {
  type = string
  default = null
}

variable "ecs_task_ipc_mode" {
  type = string
  default = null
}

data "aws_region" "log_group_region" {}
data "aws_caller_identity" "default" {}
data "aws_region" "default" {}

resource "aws_ecs_task_definition" "task" {
  container_definitions = var.datadog_enabled == true ? jsonencode(concat([ local.ecs_task_definition ], local.datadog_task_definition)) : jsonencode([ local.ecs_task_definition ])
  cpu = var.ecs_task_cpu
  memory = var.ecs_task_memory
  family = var.ecs_task_family == null ? local.ecs_task_name : var.ecs_task_family
  network_mode = "awsvpc"
  requires_compatibilities = upper(var.ecs_launch_type) == "FARGATE" ? ["EC2", "FARGATE"] : ["EC2"]
  tags = var.ecs_task_tags
  ipc_mode = var.ecs_task_ipc_mode
  pid_mode = var.ecs_task_pid_mode
  execution_role_arn = aws_iam_role.iam_role_execution.arn
  task_role_arn = aws_iam_role.iam_role_task.arn
  dynamic "volume" {
    for_each = var.ecs_task_volumes
    content {
      name = volume.value
    }
  }
  dynamic "volume" {
    for_each = var.ecs_task_volumes_efs
    content {
      name = volume.value["name"]
      efs_volume_configuration {
        transit_encryption = volume.value["transit_encryption"]
        transit_encryption_port = volume.value["transit_encryption_port"]
        file_system_id = volume.value["file_system_id"]
        root_directory = volume.value["root_directory"]
      }
    }
  }
  lifecycle {
    ignore_changes = [ revision, tags ]
  }
}
