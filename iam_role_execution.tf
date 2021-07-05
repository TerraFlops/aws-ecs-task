resource "aws_iam_role" "iam_role_execution" {
  name = "${local.ecs_task_name}EcsExecutionRole"
  description = "Role used by Fargate to start the ${local.ecs_task_name} ECS task"
  assume_role_policy = data.aws_iam_policy_document.iam_role_execution_assume_role.json
}

resource "aws_iam_role_policy" "iam_role_execution" {
  role = aws_iam_role.iam_role_execution.name
  policy = data.aws_iam_policy_document.iam_role_execution.json
  name = "EcsExecutionRole"
}

data "aws_iam_policy_document" "iam_role_execution" {
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
    resources = ["*"]
  }
  statement {
    effect = "Allow"
    actions = [
      "ssm:GetParameters",
      "secretsmanager:GetSecretValue",
      "kms:Decrypt"
    ]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "iam_role_execution_assume_role" {
  version = "2012-10-17"
  statement {
    effect = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      identifiers = ["ecs-tasks.amazonaws.com"]
      type = "Service"
    }
  }
}
