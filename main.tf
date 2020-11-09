# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Internal variable wrangling
# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

locals {
  ecs_task_name = join("", [for element in split("_", lower(var.name)) : title(element)])
  ecs_task_family = var.ecs_task_family == null ? local.ecs_task_name : var.ecs_task_family
  ecr_repository_name = lower(replace(var.name, "_", "-"))

  # If a role name was specified as a module variable, use that- otherwise procedurally generate the IAM roles name
  ecs_execution_iam_role_name = var.ecs_execution_role_name == null ? "${local.ecs_task_name}EcsExecutionRole" : var.ecs_execution_role_name
  ecs_task_iam_role_name = var.ecs_task_role_name == null ? "${local.ecs_task_name}EcsTaskRole" : var.ecs_task_role_name

  # Get the ARN of the load balancer certificate to use (if any)
  alb_certificate_arn = var.alb_certificate_arn == null ? (var.alb_listener_protocol == "https" && var.alb_enabled == true && var.alb_certificate_arn == null ? module.task_alb_certificate[0].acm_certificate_arn : null) : var.alb_certificate_arn
}

# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Create load balancer
# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

# Create an ACM certificate for the load balancer if we are using HTTPS
module "task_alb_certificate" {
  count = var.alb_listener_protocol == "https" && var.alb_enabled == true && var.alb_certificate_arn == null ? 1 : 0
  source = "git::https://github.com/TerraFlops/aws-acm-certificate.git?ref=v2.1"
  domain_name = var.alb_certificate_subject_name
  hosted_zone_id = var.alb_dns_record_hosted_zone_id
  subject_alternative_names = var.alb_certificate_alternate_names
}

# Create application load balancer if required
module "task_alb" {
  depends_on = [
    module.task_alb_certificate
  ]
  count = var.alb_enabled == true ? 1 : 0
  source = "git::https://github.com/TerraFlops/aws-ecs-blue-green-load-balancer?ref=v1.3"
  name = var.name
  internal = var.alb_internal

  # Setup log bucket
  log_bucket = var.alb_log_bucket
  log_bucket_create = true

  # Setup listener
  listener_port = var.alb_listener_port
  listener_protocol = var.alb_listener_protocol
  listener_certificate_arn = var.alb_listener_protocol == "https" ? local.alb_certificate_arn : null

  # Setup target
  target_type = "ip"
  target_port = var.alb_target_port
  target_protocol = var.alb_target_protocol
  deregistration_delay = var.alb_deregistration_delay

  # Setup health check
  health_check_port = var.alb_health_check_port
  health_check_url = var.alb_health_check_url
  health_check_protocol = var.alb_health_check_protocol
  health_check_response_codes = join(",", var.alb_health_check_response_codes)
  health_check_timeout = var.alb_health_check_timeout

  # Configure VPC settings
  vpc_id = var.alb_vpc_id
  security_group_ids = var.alb_security_group_ids
  subnet_ids = var.alb_subnet_ids
}

# Create vanity Route 53 CNAME record for the load balancer if requested
resource "aws_route53_record" "task_alb_cname" {
  count = var.alb_enabled == true && var.alb_dns_record_hosted_zone_id != null && var.alb_dns_record_name != null ? 1 : 0
  name = var.alb_dns_record_name
  zone_id = var.alb_dns_record_hosted_zone_id
  type = "CNAME"
  allow_overwrite = true
  ttl = 300
  records = [
    module.task_alb[0].alb_dns_name
  ]
}

# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Create ECR repository
# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

resource "aws_ecr_repository" "task" {
  count = var.ecr_repository_create == true ? 1 : 0
  name = var.ecr_repository_name == null ? local.ecr_repository_name : var.ecr_repository_name
  # Set image tagging mutability
  image_tag_mutability = var.ecr_repository_image_tag_mutability
  # Enable image scanning on the repository- its free so I can't see any reason to not enable this
  image_scanning_configuration {
    scan_on_push = true
  }
}

# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# ECS Execution Role
# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

# Create ECS task execution IAM role
module "ecs_execution_iam_role" {
  count = var.ecs_execution_role_name_create == true ? 1 : 0
  source = "git::https://github.com/TerraFlops/aws-iam-roles.git?ref=v2.2"
  name = local.ecs_execution_iam_role_name
  description = "Role used by Fargate/ECS to start ${local.ecs_task_name} ECS task"
  assume_role_policy = data.aws_iam_policy_document.ecs_execution_assume_role.json
  policies = []
  inline_policies = [
    {
      name = "EcsExecutionRole"
      policy_document = data.aws_iam_policy_document.ecs_execution_iam_role.json
    }
  ]
}

# If we are not creating a role, find the existing role name that was specified
data "aws_iam_role" "ecs_execution_iam_role" {
  count = var.ecs_execution_role_name_create == false ? 1 : 0
  name = local.ecs_execution_iam_role_name
}

# Create policy allowing Fargate/ECS to deploy the task from ECR repository
data "aws_iam_policy_document" "ecs_execution_iam_role" {
  version = "2012-10-17"
  statement {
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      "*"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "ssm:GetParameters",
      "secretsmanager:GetSecretValue",
      "kms:Decrypt"
    ]
    resources = [
      "*"
    ]
  }
}

# Create policy document allowing Fargate/ECS tasks to assume the role
data "aws_iam_policy_document" "ecs_execution_assume_role" {
  version = "2012-10-17"
  statement {
    effect = "Allow"
    actions = [
      "sts:AssumeRole"
    ]
    principals {
      identifiers = [
        "ecs-tasks.amazonaws.com"
      ]
      type = "Service"
    }
  }
}

# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# ECS Task Role
# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

# Create role that will be assigned for runtime usage by the ECS task
module "ecs_task_iam_role" {
  count = var.ecs_task_role_name_create == true ? 1 : 0
  source = "git::https://github.com/TerraFlops/aws-iam-roles.git?ref=v2.2"
  name = local.ecs_task_iam_role_name
  description = "Role used by the running ${local.ecs_task_name} ECS task"
  assume_role_policy = data.aws_iam_policy_document.task_assume_role.json
  policies = []
  inline_policies = var.ecs_task_runtime_policies
}

# If we are not creating a role, find the existing role name that was specified
data "aws_iam_role" "ecs_task_iam_role" {
  count = var.ecs_task_role_name_create == false ? 1 : 0
  name = local.ecs_task_iam_role_name
}

# Create policy document allowing ECS tasks to assume a role
data "aws_iam_policy_document" "task_assume_role" {
  version = "2012-10-17"
  statement {
    effect = "Allow"
    actions = [
      "sts:AssumeRole"
    ]
    principals {
      identifiers = [
        "ecs-tasks.amazonaws.com"
      ]
      type = "Service"
    }
  }
}

# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Create ECS task definition
# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

locals {
  ecr_repository_tag_parameter_name = "${var.ecr_repository_tag_parameter_prefix}${local.ecs_task_name}"
  ecs_task_definition_template_name = "${var.ecs_task_definition_template_parameter_prefix}${local.ecs_task_name}"
}

# Get the default provider region if none was specified for the log group
data "aws_region" "log_group_region" {}

# Create an SSM parameter to store the deployed version
resource "aws_ssm_parameter" "ecr_repository_tag" {
  name = local.ecr_repository_tag_parameter_name
  type = "String"
  value = var.ecr_repository_initial_tag
  # Ignore any change made to the value so we dont keep reapplying the initial tag
  lifecycle {
    ignore_changes = [
      value
    ]
  }
}

resource "aws_ssm_parameter" "ecs_task_definition_template" {
  name = local.ecs_task_definition_template_name
  type = "String"
  value = module.ecs_container_definition_template.json
}

# Always read the most recent tag value for use in the container definition
data "aws_ssm_parameter" "ecr_repository_tag" {
  depends_on = [
    aws_ssm_parameter.ecr_repository_tag
  ]
  name = local.ecr_repository_tag_parameter_name
}

# Create a template JSON document for storage in SSM parameter store
module "ecs_container_definition_template" {
  source = "git::https://github.com/TerraFlops/aws-ecs-container-definition?ref=v1.6"
  name = local.ecs_task_name
  repository_name = var.ecr_repository_name == null ? local.ecr_repository_name : var.ecr_repository_name
  repository_tag = var.ecs_task_definition_template_tag
  cpu = var.ecs_task_cpu
  secrets = var.ecs_secrets
  memory = var.ecs_task_memory
  working_directory = var.ecs_task_working_directory
  read_only_root_filesystem = var.read_only_root_filesystem
  port_mappings = var.ecs_task_port_mappings
  entry_point = var.ecs_task_entry_point
  command = var.ecs_task_command
  volumes = var.ecs_task_volumes
  volumes_efs = var.ecs_task_volumes_efs
  mount_points = var.ecs_task_mount_points
  environment_variables = var.ecs_task_environment_variables
  log_group_name = var.ecs_task_log_group_name == null ? var.ecs_cluster_name : var.ecs_task_log_group_name
  log_group_region = var.ecs_task_log_group_region == null ? data.aws_region.log_group_region.name : var.ecs_task_log_group_region
}

# Create task definition
resource "aws_ecs_task_definition" "task" {
  container_definitions = replace(module.ecs_container_definition_template.json_array, var.ecs_task_definition_template_tag, aws_ssm_parameter.ecr_repository_tag.value)
  cpu = module.ecs_container_definition_template.cpu
  memory = module.ecs_container_definition_template.memory
  family = local.ecs_task_family
  network_mode = "awsvpc"
  requires_compatibilities = upper(var.ecs_launch_type) == "FARGATE" ? [
    "EC2",
    "FARGATE"] : [
    "EC2"]

  # Associate the IAM task/execution roles
  execution_role_arn = var.ecs_execution_role_name_create == true ? module.ecs_execution_iam_role[0].iam_role_arn : data.aws_iam_role.ecs_execution_iam_role[0].arn
  task_role_arn = var.ecs_task_role_name_create == true ? module.ecs_task_iam_role[0].iam_role_arn : data.aws_iam_role.ecs_task_iam_role[0].arn

  # Attach Docker volumes
  dynamic "volume" {
    for_each = module.ecs_container_definition_template.volumes
    content {
      name = volume.value
    }
  }

  # Attach EFS volumes
  dynamic "volume" {
    for_each = var.ecs_task_volumes_efs
    content {
      name = volume.value["name"]
      efs_volume_configuration {
        file_system_id = volume.value["file_system_id"]
        root_directory = volume.value["root_directory"]
      }
    }
  }
}

# Create ECS service
resource "aws_ecs_service" "task" {
  depends_on = [
    module.task_alb
  ]

  # Ignore changes to the task definition
  lifecycle {
    ignore_changes = [
      task_definition,
      desired_count
    ]
  }

  name = local.ecs_task_name
  cluster = var.ecs_cluster_name
  task_definition = aws_ecs_task_definition.task.arn
  launch_type = upper(var.ecs_launch_type)

  # Configure deployment settings
  desired_count = var.ecs_task_desired_count
  deployment_minimum_healthy_percent = var.ecs_service_deployment_minimum_healthy_percent
  deployment_maximum_percent = var.ecs_service_deployment_maximum_percent
  platform_version = var.ecs_platform_version
  deployment_controller {
    type = var.ecs_service_deployment_controller
  }

  # Configure network settings
  network_configuration {
    subnets = var.ecs_task_subnet_ids
    assign_public_ip = var.ecs_task_assign_public_ip
    security_groups = var.ecs_task_security_group_ids
  }

  # Setup load balancer if requested
  health_check_grace_period_seconds = var.alb_enabled == true ? var.alb_health_check_grace_period_seconds : null
  dynamic "load_balancer" {
    for_each = var.alb_enabled == false ? {} : tomap({
      load_balancer = {
        target_group_arn = module.task_alb[0].green_target_group_arn
        container_name = local.ecs_task_name
        container_port = var.alb_target_port
      }
    })
    content {
      target_group_arn = load_balancer.value["target_group_arn"]
      container_name = load_balancer.value["container_name"]
      container_port = load_balancer.value["container_port"]
    }
  }

  # Setup service registry
  dynamic "service_registries" {
    for_each = var.service_registry_arn == null ? {} : tomap({
      service_registries = {
        registry_arn = var.service_registry_arn
        container_name = local.ecs_task_name
      }
    })
    content {
      registry_arn = service_registries.value["registry_arn"]
      container_name = service_registries.value["container_name"]
    }
  }
}

resource "aws_appautoscaling_target" "task" {
  depends_on = [
    aws_ecs_service.task
  ]
  count = var.ecs_task_scaling_enabled == true ? 1 : 0
  max_capacity = var.ecs_task_scaling_maximum
  min_capacity = var.ecs_task_scaling_minimum
  resource_id = "service/${var.ecs_cluster_name}/${local.ecs_task_name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace = "ecs"
}

resource "aws_appautoscaling_policy" "task_cpu_scale_down" {
  depends_on = [
    aws_ecs_service.task
  ]
  count = var.ecs_task_scaling_enabled == true ? 1 : 0
  name = "${var.ecs_cluster_name}${local.ecs_task_name}CpuScaleDown"
  policy_type = "StepScaling"
  resource_id = aws_appautoscaling_target.task[0].resource_id
  scalable_dimension = aws_appautoscaling_target.task[0].scalable_dimension
  service_namespace = aws_appautoscaling_target.task[0].service_namespace
  step_scaling_policy_configuration {
    adjustment_type = "ChangeInCapacity"
    cooldown = 120
    metric_aggregation_type = var.ecs_task_scaling_cpu_statistic
    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment = var.ecs_task_scaling_cpu_down_adjustment
    }
  }
}

resource "aws_appautoscaling_policy" "task_cpu_scale_up" {
  depends_on = [
    aws_ecs_service.task
  ]
  count = var.ecs_task_scaling_enabled == true ? 1 : 0
  name = "${var.ecs_cluster_name}${local.ecs_task_name}CpuScaleUp"
  policy_type = "StepScaling"
  resource_id = aws_appautoscaling_target.task[0].resource_id
  scalable_dimension = aws_appautoscaling_target.task[0].scalable_dimension
  service_namespace = aws_appautoscaling_target.task[0].service_namespace
  step_scaling_policy_configuration {
    adjustment_type = "ChangeInCapacity"
    cooldown = 60
    metric_aggregation_type = var.ecs_task_scaling_cpu_statistic
    step_adjustment {
      metric_interval_upper_bound = 0
      scaling_adjustment = var.ecs_task_scaling_cpu_up_adjustment
    }
  }
}

resource "aws_cloudwatch_metric_alarm" "cpu_utilization_up_scale" {
  depends_on = [
    aws_ecs_service.task,
    aws_appautoscaling_policy.task_cpu_scale_up
  ]
  alarm_name = "${var.ecs_cluster_name}${local.ecs_task_name}CpuUtilizationUp"
  comparison_operator = var.ecs_task_scaling_cpu_comparison_up
  evaluation_periods = var.ecs_task_scaling_cpu_evaluation_periods
  metric_name = "CPUUtilization"
  namespace = "AWS/ECS"
  period = var.ecs_task_scaling_cpu_period
  statistic = var.ecs_task_scaling_cpu_statistic
  threshold = var.ecs_task_scaling_cpu_threshold_up
  dimensions = {
    ServiceName = local.ecs_task_name
    ClusterName = var.ecs_cluster_name
  }
  alarm_description = "Monitor ${local.ecs_task_name} ECS task CPU usage"
  alarm_actions = var.ecs_task_scaling_enabled == true ? [
    aws_appautoscaling_policy.task_cpu_scale_up[0].arn
  ] : []
}

resource "aws_cloudwatch_metric_alarm" "cpu_utilization_down_scale" {
  depends_on = [
    aws_ecs_service.task,
    aws_appautoscaling_policy.task_cpu_scale_down
  ]
  alarm_name = "${var.ecs_cluster_name}${local.ecs_task_name}CpuUtilizationDown"
  comparison_operator = var.ecs_task_scaling_cpu_comparison_down
  evaluation_periods = var.ecs_task_scaling_cpu_evaluation_periods
  metric_name = "CPUUtilization"
  namespace = "AWS/ECS"
  period = var.ecs_task_scaling_cpu_period
  statistic = var.ecs_task_scaling_cpu_statistic
  threshold = var.ecs_task_scaling_cpu_threshold_down
  dimensions = {
    ServiceName = local.ecs_task_name
    ClusterName = var.ecs_cluster_name
  }
  alarm_description = "Monitor ${local.ecs_task_name} ECS task CPU usage"
  alarm_actions = var.ecs_task_scaling_enabled == true ? [
    aws_appautoscaling_policy.task_cpu_scale_down[0].arn
  ] : []
}

resource "aws_cloudwatch_metric_alarm" "cpu_utilization_up_sms" {
  depends_on = [
    aws_ecs_service.task
  ]
  alarm_name = "${var.ecs_cluster_name}${local.ecs_task_name}CpuUtilizationUpSms"
  comparison_operator = var.ecs_task_scaling_cpu_comparison_up
  evaluation_periods = var.ecs_task_scaling_cpu_evaluation_periods
  metric_name = "CPUUtilization"
  namespace = "AWS/ECS"
  period = var.ecs_task_scaling_cpu_period
  statistic = var.ecs_task_scaling_cpu_statistic
  threshold = var.ecs_task_scaling_cpu_threshold_up
  dimensions = {
    ServiceName = local.ecs_task_name
    ClusterName = var.ecs_cluster_name
  }
  alarm_description = "Monitor ${local.ecs_task_name} ECS task CPU usage"
  alarm_actions = [
    aws_sns_topic.cpu_utilization_up_sms.arn
  ]
}

resource "aws_sns_topic" "cpu_utilization_up_sms" {
  name = "${var.ecs_cluster_name}${local.ecs_task_name}CpuUtilizationUpSms"
}

resource "aws_sns_topic_subscription" "cpu_utilization_up_sms" {
  for_each = var.ecs_task_scaling_alarm_sms_numbers
  endpoint = each.value
  protocol = "sms"
  topic_arn = aws_sns_topic.cpu_utilization_up_sms.arn
}
