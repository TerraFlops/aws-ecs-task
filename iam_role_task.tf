resource "aws_iam_role" "iam_role_task" {
  name = "${local.application_name_snake}${local.ecs_task_name}EcsTaskRole"
  description = "Role used by the ${local.ecs_task_name} ECS task"
  assume_role_policy = data.aws_iam_policy_document.iam_role_task.json
}

data "aws_iam_policy_document" "iam_role_task" {
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
