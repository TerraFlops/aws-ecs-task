variable "ecs_task_start_timeout" {
  description = "Optional override to container start timeout"
  type = number
  default = 120
}

variable "ecs_task_stop_timeout" {
  description = "Optional override to container stop timeout"
  type = number
  default = 120
}

variable "datadog_enabled" {
  description = "Boolean flag, if true the DataDog sidecar will be added to the container"
  type = bool
  default = false
}

variable "datadog_environment" {
  description = "Application deployment environment"
  type = string
  default = "unknown"
}

variable "datadog_trace_symfony" {
  description = "Enable trace integration"
  type = bool
  default = false
}

variable "datadog_trace_guzzle" {
  description = "Enable trace integration"
  type = bool
  default = false
}

variable "datadog_trace_lumen" {
  description = "Enable trace integration"
  type = bool
  default = false
}

variable "datadog_trace_eloquent" {
  description = "Enable trace integration"
  type = bool
  default = false
}

variable "datadog_trace_laravel" {
  description = "Enable trace integration"
  type = bool
  default = false
}

variable "datadog_trace_pdo" {
  description = "Enable trace integration"
  type = bool
  default = false
}

variable "datadog_cpu" {
  description = "Optional override for the CPU reservation of the Datadog agent"
  type = number
  default = 10
}

variable "datadog_memory" {
  description = "Optional override for the CPU reservation of the Datadog agent"
  type = number
  default = 256
}

variable "datadog_api_key_parameter_name" {
  description = "Name of the SSM parameter that contains the Datadog API key"
  type = string
  default = "Datadog/API_KEY"
}

locals {
  datadog_docker_labels = var.datadog_enabled == false ? null : {
    "com.datadoghq.ad.instances" = jsonencode([
      for port_mapping in var.ecs_task_port_mappings: {
        port = port_mapping["port"]
        host = "%%host%%"
      }
    ])
    "com.datadoghq.ad.check_names" = "[]",
    "com.datadoghq.ad.init_configs" = "[{}]"
  }
  datadog_task_definition = [
    {
      name = "${local.ecs_task_name}DatadogAgent"
      image = "datadog/agent:latest",
      cpu = var.datadog_cpu
      memory = var.datadog_memory
      essential = true
      secrets = [
        { name = "DD_API_KEY", valueFrom = "arn:aws:ssm:${data.aws_region.default.name}:${data.aws_caller_identity.default.account_id}:parameter/${var.datadog_api_key_parameter_name}" }
      ]
      environment = [
        { name = "DD_APM_ENABLED", value = "true" },
        { name = "DD_SERVICE", value = local.ecs_task_name },
        { name = "DD_TRACE_ENABLED", value = "true" },
        { name = "DD_TRACE_DEBUG", value = "true" },
        { name = "DD_TRACE_ELOQUENT_ENABLED", value = var.datadog_trace_eloquent == true ? "true" : "false" },
        { name = "DD_TRACE_GUZZLE_ENABLED", value = var.datadog_trace_guzzle == true ? "true" : "false" },
        { name = "DD_TRACE_LARAVEL_ENABLED", value = var.datadog_trace_laravel == true ? "true" : "false" },
        { name = "DD_TRACE_LUMEN_ENABLED", value = var.datadog_trace_lumen == true ? "true" : "false" },
        { name = "DD_TRACE_PDO_ENABLED", value = var.datadog_trace_pdo == true ? "true" : "false" },
        { name = "DD_TRACE_SYMFONY_ENABLED", value = var.datadog_trace_symfony == true ? "true" : "false" },
        { name = "DD_ENV", value = var.datadog_environment },
        { name = "ECS_FARGATE", value = "true" }
      ]
      dnsSearchDomains = null
      environmentFiles = null
      firelensConfiguration = null
      dependsOn = null
      disableNetworking = null
      interactive = null
      healthCheck = null
      essential = true
      links = null
      hostname = null
      extraHosts = null
      pseudoTerminal = null
      user = null
      dockerLabels = null
      systemControls = null
      privileged = null
      linuxParameters = null
      resourceRequirements = null
      dnsServers = null
      dockerSecurityOptions = null
      memoryReservation = null
      volumesFrom = null
    }
  ]

  ecs_task_definition = merge({
      name = local.ecs_task_name
      cpu = var.ecs_task_cpu - var.datadog_cpu
      memory = var.ecs_task_memory - var.datadog_memory
      workingDirectory = var.ecs_task_working_directory
      entryPoint = var.ecs_task_entry_point
      command = var.ecs_task_command
      startTimeout = var.ecs_task_start_timeout
      stopTimeout = var.ecs_task_stop_timeout
      image = "${data.aws_caller_identity.default.account_id}.dkr.ecr.${data.aws_region.default.name}.amazonaws.com/${local.ecr_repository_name}:${aws_ssm_parameter.ecr_repository_tag.value}"
      readonlyRootFilesystem = var.ecs_task_read_only_filesystem
      dnsSearchDomains = null
      environmentFiles = null
      firelensConfiguration = null
      dependsOn = null
      disableNetworking = null
      interactive = null
      healthCheck = null
      essential = true
      links = null
      hostname = null
      extraHosts = null
      pseudoTerminal = null
      user = null
      dockerLabels = local.datadog_docker_labels
      systemControls = null
      privileged = null
      linuxParameters = null
      resourceRequirements = null
      dnsServers = null
      dockerSecurityOptions = null
      memoryReservation = null
      volumesFrom = null
      logConfiguration = {
        logDriver = "awslogs"
        secretOptions = null
        options = {
          "awslogs-group" = var.ecs_cluster_name
          "awslogs-region" = data.aws_region.default.name
          "awslogs-stream-prefix" = local.ecs_task_name
        }
      }
    },
    # Secrets Manager Secrets
    length(var.ecs_task_secrets) == 0 ? {} : {
      secrets = [
        for secret_name, secret_arn in var.ecs_task_secrets: {
          name = secret_name
          valueFrom = secret_arn
        }
      ]
    },
    # Docker Volumes
    length(var.ecs_task_volumes) == 0 ? {} : {
      volumes = [
        for volume in var.ecs_task_volumes: {
          dockerVolumeConfiguration = null
          efsVolumeConfiguration = null
          host = { sourcePath = null }
          name = volume
        }
      ]
    },
    # EFS Volumes
    length(var.ecs_task_volumes_efs) == 0 ? {} : {
      volumes_efs = [
        for volume_efs in var.ecs_task_volumes_efs: {
          dockerVolumeConfiguration = null
          efsVolumeConfiguration = {
            fileSystemId = volume_efs["file_system_id"]
            rootDirectory = volume_efs["root_directory"]
          }
          name = volume_efs["name"]
        }
      ]
    },
    # Port Mappings
    length(var.ecs_task_port_mappings) == 0 ? {} : {
      portMappings = [
        for port_mapping in var.ecs_task_port_mappings: {
          hostPort = port_mapping["port"]
          containerPort = port_mapping["port"]
          protocol = lower(port_mapping["protocol"])
        }
      ]
    },
    # Mount points
    length(var.ecs_task_mount_points) == 0 ? {} : {
      mountPoints = [
        for mount_point in var.ecs_task_mount_points: {
          readOnly: mount_point["read_only"]
          containerPath: mount_point["container_path"]
          sourceVolume: mount_point["source_volume"]
        }
      ]
    },
    # Environment variables
    length(var.ecs_task_environment_variables) == 0 ? {} : {
      environment = [
        for key, value in merge(var.ecs_task_environment_variables, {
          "AWS_ECS_TASK_NAME": var.ecs_task_name
        }): tomap({
          name: key
          value: value
        })
      ]
    }
  )
}

