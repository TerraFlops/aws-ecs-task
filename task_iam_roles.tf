# Create role that will be assigned for runtime usage by the ECS task
module "task_iam_role" {
  source = "git::https://github.com/TerraFlops/aws-iam-roles.git?ref=v2.2"
  name = "${local.container_name_title}TaskRole"
  description = "Role used by ${local.container_name_title} ECS task"
  assume_role_policy = data.aws_iam_policy_document.task_assume_role.json
  inline_policies = var.container_runtime_policies
  policies = []
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