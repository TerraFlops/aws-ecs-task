variable "ecr_repository_create" {
  description = "Boolean flag, if true a new ECR repository will be created for the task (defaults to True)"
  type = bool
  default = true
}

variable "ecr_repository_name" {
  description = "Optional override for the repository name, if no repository name is supplied the ECS task name will be used"
  type = string
  default = null
}

variable "ecr_repository_initial_tag" {
  description = "The initial ECR repository image tag to set by default on ECS service. If non supplied will be set to 'initial'"
  type = string
  default = "initial"
}

variable "ecr_repository_image_tag_mutability" {
  description = "Optional override, if creating the ECR repository this will define the mutability of image tags (defaults to 'IMMUTABLE')"
  type = string
  default = "IMMUTABLE"
}

variable "ecr_repository_scan_on_push" {
  description = "Optional override, boolean flag, if true will perform container vulnerability scans on every new image pushed to ECR (defaults to True)"
  default = true
}

variable "ecr_repository_tag_parameter_prefix" {
  description = "Prefix prepended to the SSM parameter which stores the currently deployed image tag (include trailing slash if you are specify a root path)"
  type = string
  default = "/Terraform/ECS/Tag/"
}

locals {
    ecr_repository_name = var.ecr_repository_name == null ? lower(replace(var.ecs_task_name, "_", "-")) : var.ecr_repository_name
}

resource "aws_ecr_repository" "task" {
  count = var.ecr_repository_create == true ? 1 : 0
  name = local.ecr_repository_name
  image_tag_mutability = var.ecr_repository_image_tag_mutability
  image_scanning_configuration {
    scan_on_push = var.ecr_repository_scan_on_push
  }
}

resource "aws_ssm_parameter" "ecr_repository_tag" {
  name = "${var.ecr_repository_tag_parameter_prefix}${local.ecs_task_name}"
  type = "String"
  value = var.ecr_repository_initial_tag
  lifecycle {
    ignore_changes = all
  }
}
