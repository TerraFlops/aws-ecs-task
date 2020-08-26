# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Mangle variables into usable locals
# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

locals {
  container_name_hyphen = lower(replace(var.container_name, "_", "-"))
  container_name_title = join("", [ for element in split("_", lower(var.container_name)) : title(element) ])
}

# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Task container settings
# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

variable "cluster_name" {
  description = "Name of existing ECS cluster into which tasks will be placed"
  type = string
}

variable "ecr_repository_create" {
  description = "Boolean flag, is true a new ECR repository will be created for the task"
  type = bool
  default = true
}

variable "ecr_repository_name" {
  description = "Optional override for the repository name, if none supplied the task name will be used"
  type = string
  default = null
}

variable "container_name" {
  description = "Name of the task in snake cake (e.g. 'backend_task')"
  type = string
}

variable "container_runtime_policies" {
  description = "List of IAM policy documents to add to the ECS task for use at runtime"
  type = list(object({
    name = string
    policy_document = string
  }))
}

variable "launch_type" {
  description = "ECS launch type"
  type = string
  default = "FARGATE"
}

variable "platform_version" {
  description = "ECS platform version"
  type = string
  default = "1.4.0"
}

variable "container_desired_count" {
  description = "Number of desired tasks to execute"
  type = number
  default = 1
}

variable "container_cpu" {
  description = "The number of CPU units the ECS container agent will reserve for the container. This must fit within the total amount of reserved CPU for all containers in the task"
  type = number
}

variable "container_memory" {
  description = "The amount of memory (in MiB) to reserve for the container. This must fit within the total amount of reserved memory for all containers in the task"
  type = number
}

variable "container_working_directory" {
  description = "Optional working directory"
  type = string
  default = null
}

variable "container_log_group_name" {
  description = "Optional CloudWatch log group name override. If none supplied the ECS cluster name will be used"
  type = string
  default = null
}

variable "container_log_group_region" {
  description = "Optional CloudWatch log region override. If none specified defaults to the current Terraform AWS provider region"
  type = string
  default = null
}

variable "container_entry_point" {
  description = "Optional entrypoint override"
  type = list(string)
  default = []
}

variable "container_command" {
  description = "Optional command that is passed to the container"
  type = list(string)
  default = []
}

variable "container_security_group_ids" {
  type = list(string)
  default = []
}

variable "container_assign_public_ip" {
  type = bool
  default = false
}

variable "container_subnet_ids" {
  type = list(string)
  default = []
}

variable "container_volumes" {
  description = "Optional list of volume names"
  type = list(string)
  default = []
}

variable "container_volumes_efs" {
  description = "Optional list of EFS volumes to attach"
  type = list(object({
    name = string
    file_system_id = string
    root_directory = string
  }))
  default = []
}

variable "container_port_mappings" {
  description = "Optional list of port mappings"
  type = list(object({
    protocol = string
    port = number
  }))
  default = []
}

variable "container_mount_points" {
  description = "Optional list of mount points in the Docker container"
  type = list(object({
    read_only = bool
    container_path = string
    source_volume = string
  }))
  default = []
}

variable "container_environment_variables" {
  description = "Optional map of environment variables"
  type = map(string)
  default = {}
}

# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Load balancer settings
# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

variable "load_balancer_enabled" {
  type = bool
  default = false
}

variable "load_balancer_security_group_ids" {
  type = list(string)
  default = []
}

variable "load_balancer_subnet_ids" {
  type = list(string)
  default = []
}

variable "load_balancer_vpc_id" {
  type = string
  default = null
}

variable "load_balancer_dns_record_hosted_zone_id" {
  type = string
  default = null
}

variable "load_balancer_certificate_subject_name" {
  type = string
  default = null
}

variable "load_balancer_certificate_alternate_names"  {
  type = list(string)
  default = []
}

variable "load_balancer_dns_record_name" {
  type = string
  default = null
}

variable "load_balancer_log_bucket" {
  type = string
  default = null
}

variable "load_balancer_listener_port" {
  type = number
  default = 443
}

variable "load_balancer_listener_protocol" {
  type = string
  default = "https"
}

variable "load_balancer_target_port" {
  type = number
  default = 8080
}

variable "load_balancer_target_protocol" {
  type = string
  default = "http"
}

variable "load_balancer_deregistration_delay" {
  type = number
  default = 45
}

variable "load_balancer_health_check_port" {
  type = number
  default = 8080
}

variable "load_balancer_health_check_url" {
  type = string
  default = "/ping"
}

variable "load_balancer_health_check_protocol" {
  type = string
  default = "http"
}

variable "load_balancer_health_check_timeout" {
  type = number
  default = 5
}

variable "load_balancer_health_check_response_codes" {
  type = list(number)
  default = [200]
}