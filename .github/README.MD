# Terraflops Terraform Module
 
### AWS ECS Task

This module can be used to provision an ECS task.

#### Example usage

```hcl-terraform
module "example" {
  source = "git::https://github.com/TerraFlops/aws-ecs-task?ref=v1.0"
  # Put the task into the shared cluster created in `ecs_prerequisites.tf` file
  cluster_name = aws_ecs_cluster.example.name

  # Set basic container details
  container_name = "logstash"
  container_cpu = 1024
  container_memory = 2048

  # Attach the IAM policy documents that the task will be given for use during runtime
  container_runtime_policies = [
    {
      name = "ExamplePolicy"
      policy_document = data.aws_iam_policy_document.example.json
    }
  ]

  # Configure environment variables that will be set on the container at launch. This should be limited to the bare minimum required to
  # bootstrap the application container, and should never contain application configuration details or secrets- these should be stored in
  # AWS Systems Manager or AWS Secrets Manager
  container_environment_variables = {
  }

  # The ECS task module forces the containers filesystem to be configured in read-only mode. To work around this for folder which
  # do legitimately require write access we must configure Docker volumes
  container_volumes = local.optus_qr_connect_container_volumes

  # Add EFS volume for Logstash to allow persistent storage between executions of the task
  container_volumes_efs = [
    {
      name = "logstash"
      file_system_id = module.logstash_efs_volume.file_system_id
      root_directory = "/"
    }
  ]

  # Mount these volumes into the filesystem as writeable mount points
  container_mount_points = concat(
    local.optus_qr_connect_container_mount_points,
    [
      {
        read_only = false
        container_path = "/mnt/logstash"
        source_volume = "logstash"
      }
    ]
  )

  # Configure the containers VPC settings
  container_security_group_ids = [
    module.vpc_optus_qr_connect.security_group_ids["logstash"]
  ]

  # Configure the subnets in which the container will be placed
  container_subnet_ids = [
    module.vpc_optus_qr_connect.subnet_ids["compute_subnet_2a"],
    module.vpc_optus_qr_connect.subnet_ids["compute_subnet_2b"]
  ]
}
```
