variable "ecs_task_name" {
  description = "Name of the new task to be created. This must be entered in hyphen-case in order for auto-generation of other names to work correctly (e.g. 'lorem-ipsum')"
  type = string
}

variable "ecs_cluster_name" {
  description = "Name of existing ECS cluster into which tasks will be placed"
  type = string
}

variable "ecs_task_desired_count" {
  description = "Number of desired tasks to execute"
  type = number
  default = 1
}

variable "ecs_task_cpu" {
  description = "The number of CPU units the ECS container agent will reserve for the container. This must fit within the total amount of reserved CPU for all containers in the task"
  type = number
}

variable "ecs_task_memory" {
  description = "The amount of memory (in MiB) to reserve for the container. This must fit within the total amount of reserved memory for all containers in the task"
  type = number
}

variable "ecs_task_working_directory" {
  description = "Optional working directory"
  type = string
  default = null
}

variable "ecs_task_log_group_name" {
  description = "Optional CloudWatch log group name override. If none supplied the ECS cluster name will be used"
  type = string
  default = null
}

variable "ecs_task_log_group_region" {
  description = "Optional CloudWatch log region override. If none specified defaults to the current Terraform AWS provider region"
  type = string
  default = null
}

variable "ecs_task_entry_point" {
  description = "Optional override for the Docker containers entry point"
  type = list(string)
  default = null
}

variable "ecs_task_command" {
  description = "Optional override for the Docker containers command"
  type = list(string)
  default = []
}

variable "ecs_task_security_group_ids" {
  description = "Set of AWS security group IDs to apply to the container"
  type = set(string)
  default = []
}

variable "ecs_task_subnet_ids" {
  description = "Set of AWS subnet IDs into which the container will be launched"
  type = set(string)
  default = []
}

variable "ecs_task_assign_public_ip" {
  description = "Boolean flag, if true the ECS task will be assigned a public IP address"
  type = bool
  default = false
}

variable "ecs_task_volumes" {
  description = "Optional set of container volume names"
  type = set(string)
  default = []
}

variable "ecs_task_volumes_efs" {
  description = "Optional list of AWS EFS volumes to attach to the container"
  type = list(object({
    name = string
    transit_encryption = string
    transit_encryption_port = number
    file_system_id = string
    root_directory = string
  }))
  default = []
}

variable "ecs_task_port_mappings" {
  description = "Optional list of ports to be exposed on the container"
  type = list(object({
    protocol = string
    port = number
  }))
  default = []
}

variable "ecs_task_read_only_filesystem" {
  description = "Boolean flag, if true the ECS root filesystem will be marked as read-only."
  type = bool
  default = true
}


variable "ecs_task_mount_points" {
  description = "Optional list of mount points in the Docker container"
  type = list(object({
    read_only = bool
    container_path = string
    source_volume = string
  }))
  default = []
}

variable "ecs_task_environment_variables" {
  description = "Optional map of environment variables as key/value pairs to be assigned to tasks"
  type = map(string)
  default = {}
}

variable "ecs_launch_type" {
  description = "ECS launch type. If none specified, defaults to FARGATE"
  type = string
  default = "FARGATE"
}

variable "ecs_target_port" {
  description = "The port the load balancer will use when passing traffic to the target container. Defaults to 8080"
  type = number
  default = 8080
}

variable "ecs_service_registry_arn" {
  description = "Optional ARN of Cloud Map service registry for private service discovery"
  type = string
  default = null
}

variable "ecs_service_deployment_controller" {
  description = "Deployment controller to use for ECS, must be one of CODE_DEPLOY, ECS, or EXTERNAL. If set to 'CODE_DEPLOY' a load balancer must also be created and ports exposed from the container. Defaults to 'ECS'"
  type = string
  default = "ECS"
}

variable "ecs_service_deployment_minimum_healthy_percent" {
  description = "Minimum healthy percentage of containers to be deployed"
  type = number
  default = 50
}

variable "ecs_service_deployment_maximum_percent" {
  description = "Maximum percentage of containers to be deployed"
  type = number
  default = 600
}

variable "ecs_platform_version" {
  description = "ECS platform version, if none supplied will default to '1.4.0' which allows EFS mounting in Fargate containers"
  type = string
  default = "1.4.0"
}

variable "health_check_grace_period_seconds" {
  description = "Grace period on startup of containers before health check commences. Defaults to 120 seconds"
  type = number
  default = 120
}

locals {
  ecs_task_name = join("", [for element in split("_", lower(replace(var.ecs_task_name, "-", "_"))) : title(element)])
  health_check_grace_period_seconds = var.load_balancer_create == true ? var.health_check_grace_period_seconds : null
}

resource "aws_ecs_service" "task" {
  depends_on = [ aws_lb.application ]
  name = local.ecs_task_name
  cluster = var.ecs_cluster_name
  task_definition = aws_ecs_task_definition.task.arn
  launch_type = upper(var.ecs_launch_type)
  desired_count = var.ecs_task_desired_count
  deployment_minimum_healthy_percent = var.ecs_service_deployment_minimum_healthy_percent
  deployment_maximum_percent = var.ecs_service_deployment_maximum_percent
  platform_version = var.ecs_platform_version
  health_check_grace_period_seconds = local.health_check_grace_period_seconds
  deployment_controller {
    type = var.ecs_service_deployment_controller
  }
  network_configuration {
    subnets = var.ecs_task_subnet_ids
    assign_public_ip = var.ecs_task_assign_public_ip
    security_groups = var.ecs_task_security_group_ids
  }
  dynamic "load_balancer" {
    for_each = var.load_balancer_create == false ? {} : tomap({
      load_balancer = {
        target_group_arn = aws_lb_target_group.ecs_task.arn
        container_name = local.ecs_task_name
        container_port = var.ecs_target_port
      }
    })
    content {
      target_group_arn = load_balancer.value["target_group_arn"]
      container_name = load_balancer.value["container_name"]
      container_port = load_balancer.value["container_port"]
    }
  }
  dynamic "service_registries" {
    for_each = var.ecs_service_registry_arn == null ? {} : tomap({
      service_registries = {
        registry_arn = var.ecs_service_registry_arn
        container_name = local.ecs_task_name
      }
    })
    content {
      registry_arn = service_registries.value["registry_arn"]
      container_name = service_registries.value["container_name"]
    }
  }
  lifecycle {
    create_before_destroy = true
    ignore_changes = [
      task_definition,
      desired_count
    ]
  }
}
