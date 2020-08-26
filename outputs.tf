output "iam_role_arn" {
  value = module.task_iam_role.iam_role_arn
}

output "iam_role_name" {
  value = module.task_iam_role.iam_role_name
}

output "ecs_cluster_name" {
  value = var.cluster_name
}

output "ecs_service_id" {
  value = aws_ecs_service.task.id
}

output "ecs_service_name" {
  value = aws_ecs_service.task.name
}