# Create ECR repository
resource "aws_ecr_repository" "task" {
  count = var.ecr_repository_create == true ? 1 : 0
  name = var.ecr_repository_name == null ? local.container_name_hyphen : var.ecr_repository_name
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
}

# Create task task definition
resource "aws_ecs_task_definition" "task" {
  container_definitions = module.container_definition.json_array
  cpu = module.container_definition.cpu
  memory = module.container_definition.memory
  family = local.container_name_title
  network_mode = "awsvpc"
  requires_compatibilities = upper(var.launch_type) == "FARGATE" ? ["EC2", "FARGATE"] : ["EC2"]
  # Associate the IAM roles with the task
  execution_role_arn = module.ecs_iam_role.iam_role_arn
  task_role_arn = module.task_iam_role.iam_role_arn
  # Attach basic Docker volumes
  dynamic "volume" {
    for_each = module.container_definition.volumes
    content {
      name = volume.value
    }
  }
  # Attach EFS volumes
  dynamic "volume" {
    for_each = var.container_volumes_efs
    content {
      name = volume.value["name"]
      efs_volume_configuration {
        file_system_id = volume.value["file_system_id"]
        root_directory = volume.value["root_directory"]
      }
    }
  }
}

# Get the default provider region
data "aws_region" "default" {}

# Setup container definition
module "container_definition" {
  source = "git::https://github.com/TerraFlops/aws-ecs-container-definition?ref=v1.0"
  name = local.container_name_title
  repository_name = var.ecr_repository_name == null ? local.container_name_hyphen : var.ecr_repository_name
  cpu = var.container_cpu
  memory = var.container_memory
  working_directory = var.container_working_directory
  port_mappings = var.container_port_mappings
  entry_point = var.container_entry_point
  command = var.container_command
  volumes = var.container_volumes
  volumes_efs = var.container_volumes_efs
  mount_points = var.container_mount_points
  environment_variables = var.container_environment_variables
  log_group_name = var.container_log_group_name == null ? var.cluster_name : var.container_log_group_name
  log_group_region = var.container_log_group_region == null ? data.aws_region.default.name : var.container_log_group_region
}

# Create task service
resource "aws_ecs_service" "task" {
  depends_on = [
    module.task_alb
  ]
  name = local.container_name_title
  cluster = var.cluster_name
  task_definition = aws_ecs_task_definition.task.arn
  launch_type = upper(var.launch_type)
  # Configure deployment settings
  desired_count = var.container_desired_count
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent = 200
  platform_version = var.platform_version
  deployment_controller {
    type = var.load_balancer_enabled == true ? "CODE_DEPLOY" : "ECS"
  }
  # Configure network settings
  network_configuration {
    subnets = var.container_subnet_ids
    assign_public_ip = var.container_assign_public_ip
    security_groups = var.container_security_group_ids
  }
  # Setup load balancer
  health_check_grace_period_seconds = var.load_balancer_enabled == true ? 120 : null
  dynamic "load_balancer" {
    for_each = var.load_balancer_enabled == false ? {} : tomap({
      load_balancer = {
        target_group_arn = module.task_alb[0].green_target_group_arn
        container_name = local.container_name_title 
        container_port = var.load_balancer_target_port
      }
    })
    content {
      target_group_arn = load_balancer.value["target_group_arn"]
      container_name = load_balancer.value["container_name"]
      container_port = load_balancer.value["container_port"]
    }
  }
}
