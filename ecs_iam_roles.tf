# Create ECS task execution IAM role
module "ecs_iam_role" {
  source = "git::https://github.com/TerraFlops/aws-iam-roles.git?ref=v2.2"
  name = "${local.container_name_title}EcsExecutionRole"
  description = "Role used by Fargate/ECS to start ${local.container_name_title} ECS task"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role.json
  policies = []
  inline_policies = [
    {
      name = "EcsExecutionRole"
      policy_document = data.aws_iam_policy_document.ecs_iam_role.json
    }
  ]
}

# Create policy allowing Fargate/ECS to deploy the task from ECR repository
data "aws_iam_policy_document" "ecs_iam_role" {
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
}

# Create policy document allowing Fargate/ECS tasks to assume the role
data "aws_iam_policy_document" "ecs_assume_role" {
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