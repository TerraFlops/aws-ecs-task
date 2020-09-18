# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Task container settings
# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

variable "name" {
  description = "Name of the new task to be created. This must be entered in snake cake in order for auto-generation of other names to work correctly and meet required formatting rules (e.g. 'backend_task')"
  type = string
}

variable "ecs_cluster_name" {
  description = "Name of existing ECS cluster into which tasks will be placed"
  type = string
}

variable "ecs_execution_role_name" {
  description = "Optional override for the IAM role name that will be used to execute the ECS task. If none supplied the name will be procedurally generated in the format 'ContainerNameEcsExecutionRole' (e.g. ApiEcsExecutionRole')"
  type = string
  default = null
}

variable "ecs_secrets" {
  description = "Optional map of secrets to pass into the task definition"
  type = map(string)
  default = {}
}

variable "ecs_execution_role_name_create" {
  description = "Boolean flag, if true the ECS execution role will be created. If false it must already exist before using the module. Defaults to true"
  type = bool
  default = true
}

variable "ecs_task_role_name" {
  description = "Optional override for the IAM role name that will be used by the running ECS task. If none supplied the name will be procedurally generated in the format 'ContainerNameEcsTaskRole' (e.g. ApiEcsTaskRole')"
  type = string
  default = null
}

variable "ecs_task_role_name_create" {
  description = "Boolean flag, if true the ECS task role will be created. If false it must already exist before using the module. Defaults to true"
  type = bool
  default = true
}

variable "ecs_launch_type" {
  description = "ECS launch type. If none specified, defaults to FARGATE"
  type = string
  default = "FARGATE"
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
  default = 200
}

variable "ecs_platform_version" {
  description = "ECS platform version, if none supplied will default to '1.4.0' which allows EFS mounting in Fargate containers"
  type = string
  default = "1.4.0"
}

variable "ecr_repository_name" {
  description = "Optional override for the repository name, if none supplied the task name will be used in its hyphenated form (e.g. 'backend-api')"
  type = string
  default = null
}

variable "ecr_repository_initial_tag" {
  description = "The initial ECR repository image tag to set by default on ECS service. If non supplied will be set to 'initial'"
  type = string
  default = "initial"
}

variable "ecr_repository_tag_parameter_prefix" {
  description = "Prefix prepended to the SSM parameter which stores the currently deployed image tag (include trailing slash if you are specify a root path)"
  type = string
  default = "/Terraform/ECS/Tag/"
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

variable "ecr_repository_create" {
  description = "Boolean flag, if true a new ECR repository will be created for the task"
  type = bool
  default = true
}

variable "ecr_repository_image_tag_mutability" {
  description = "If creating the ECR repository this define the mutability of image tags. Defaults to 'IMMUTABLE'"
  type = string
  default = "IMMUTABLE"
}

variable "ecs_task_family" {
  description = "Optional override for the container family. If none supplied the container name will be used as the family"
  type = string
  default = null
}

variable "ecs_task_runtime_policies" {
  description = "List of IAM policy documents to add to the ECS task for use at runtime"
  type = list(object({
    name = string
    policy_document = string
  }))
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
  default = null
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

# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Load balancer settings
# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

variable "alb_enabled" {
  description = "Boolean flag, if true a load balancer will be created and linked to the task. Defaults to false"
  type = bool
  default = false
}

variable "alb_internal" {
  description = "Boolean flag, if true the load balancer will be internal to the VPC, if false the load balancer will be internet facing. Defaults to false"
  type = bool
  default = false
}

variable "alb_security_group_ids" {
  description = "Set of AWS security group IDs that will be added to the load balancer"
  type = set(string)
  default = []
}

variable "alb_subnet_ids" {
  description = "Set of AWS subnet IDs into which the load balancer will be created"
  type = set(string)
  default = []
}

variable "alb_vpc_id" {
  description = "The AWS VPC ID into which the load balancer will be created"
  type = string
  default = null
}

variable "alb_certificate_arn" {
  description = "If using an existing ACM certificate this should contain the ARN of the certificate to link to the load balancer"
  type = string
  default = null
}

variable "alb_certificate_subject_name" {
  description = "Primary subject name to be used on the load balancer certificate. This is required if using a HTTPS listener"
  type = string
  default = null
}

variable "alb_certificate_alternate_names" {
  description = "Optional set of alternate subject names to be added to the load balancer certificate"
  type = set(object({
    name = string
    hosted_zone_id = string
  }))
  default = []
}

variable "alb_dns_record_hosted_zone_id" {
  description = "The Route53 Hosted Zone in which the vanity DNS CNAME will be created"
  type = string
  default = null
}

variable "alb_dns_record_name" {
  description = "Optional vanity DNS CNAME record to be created pointing to the load balancer DNS name"
  type = string
  default = null
}

variable "alb_log_bucket" {
  description = "The S3 bucket that will be used for load balancer logs"
  type = string
  default = null
}

variable "alb_listener_port" {
  description = "The port the load balancer will use when listening for public traffic. Defaults to 443"
  type = number
  default = 443
}

variable "alb_listener_protocol" {
  description = "The protocol the load balancer will use when listening for public traffic. Defaults to HTTPS"
  type = string
  default = "https"
}

variable "alb_target_port" {
  description = "The port the load balancer will use when passing traffic to the target container. Defaults to 8080"
  type = number
  default = 8080
}

variable "alb_target_protocol" {
  description = "The protocol the load balancer will when passing traffic to the target container. Defaults to HTTP"
  type = string
  default = "http"
}

variable "alb_deregistration_delay" {
  description = "The number of seconds to wait before de-registering instance from the load balancer. Defaults to 45 seconds"
  type = number
  default = 45
}

variable "alb_health_check_port" {
  description = "The port to use when performing the load balancer health check"
  type = number
  default = 8080
}

variable "alb_health_check_url" {
  description = "The URL to use when performing load balancer health check. If none supplied defaults to '/ping'"
  type = string
  default = "/ping"
}

variable "alb_health_check_protocol" {
  description = "Protocol to use when performing the health check. If none supplied defaults to HTTP"
  type = string
  default = "http"
}

variable "alb_health_check_grace_period_seconds" {
  description = "Grace period on startup of containers before health check commences. Defaults to 120 seconds"
  type = number
  default = 120
}

variable "alb_health_check_timeout" {
  description = "Number of seconds to wait for expected response code before reporting a timeout"
  type = number
  default = 5
}

variable "alb_health_check_response_codes" {
  description = "Set of HTTP response codes that are considered a passing health check. If none supplied will default to HTTP 200 only"
  type = set(number)
  default = [
    200
  ]
}

variable "service_registry_arn" {
  description = "Optional service register ARN. If specified you must also supply a service registry port"
  type = string
  default = null
}

variable "service_registry_port" {
  description = "Optional service register port. If specified you must also supply a service registry ARN. Defaults to 8080"
  type = number
  default = 8080
}