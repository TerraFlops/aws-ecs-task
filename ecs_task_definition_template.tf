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

locals {
  ecs_task_definition = merge({
      name = local.ecs_task_name
      cpu = var.ecs_task_cpu
      memory = var.ecs_task_memory
      workingDirectory = var.ecs_task_working_directory
      entryPoint = var.ecs_task_entry_point
      command = var.ecs_task_command
      startTimeout = var.ecs_task_start_timeout
      stopTimeout = var.ecs_task_stop_timeout
      image = "${data.aws_caller_identity.default.account_id}.dkr.ecr.${data.aws_region.default.name}.amazonaws.com/${local.ecr_repository_name}:${var.ecs_task_definition_template_tag}"
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
      dockerLabels = null
      systemControls = null
      privileged = null
      linuxParameters = null
      resourceRequirements = null
      dnsServers = null
      dockerSecurityOptions = null
      memoryReservation = null
      logConfiguration = {
        logDriver = "awslogs"
        secretOptions = null
        options = {
          "awslogs-group" = var.ecs_task_log_group_name
          "awslogs-region" = data.aws_region.default.name
          "awslogs-stream-prefix" = local.ecs_task_name
        }
      }
    },
    # Secrets Manager Secrets
    length(var.ecs_secrets) == 0 ? [] : {
      secrets = [
        for secret_name, secret_arn in var.ecs_secrets: {
          name = secret_name
          valueFrom = secret_arn
        }
      ]
    },
    # Docker Volumes
    length(var.ecs_task_volumes) == 0 ? [] : {
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
    length(var.ecs_task_volumes_efs) == 0 ? [] : {
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
    length(var.ecs_task_port_mappings) == 0 ? [] : {
      portMappings = [
        for port_mapping in var.ecs_task_port_mappings: {
          hostPort = port_mapping["port"]
          containerPort = port_mapping["port"]
          protocol = lower(port_mapping["protocol"])
        }
      ]
    },
    # Mount points
    length(var.ecs_task_mount_points) == 0 ? [] : {
      mountPoints = [
        for mount_point in var.ecs_task_mount_points: {
          readOnly: mount_point["read_only"]
          containerPath: mount_point["container_path"]
          sourceVolume: mount_point["source_volume"]
        }
      ]
    },
    # Environment variables
    length(var.ecs_task_environment_variables) == 0 ? [] : {
      environment = [
        for key, value in var.ecs_task_environment_variables: tomap({
          name: key
          value: value
        })
      ]
    }
  )
}

