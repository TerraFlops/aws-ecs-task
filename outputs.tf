output "container_name" {
  value = local.container_name_title
}

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

output "load_balancer_arn" {
  value = var.load_balancer_enabled == true ? module.task_alb[0].alb_arn : null
}

output "blue_target_group_arn" {
  value = var.load_balancer_enabled == true ? module.task_alb[0].blue_target_group_arn : null
}

output "blue_target_group_name" {
  value = var.load_balancer_enabled == true ? module.task_alb[0].blue_target_group_name : null
}

output "green_target_group_arn" {
  value = var.load_balancer_enabled == true ? module.task_alb[0].green_target_group_arn : null
}

output "green_target_group_name" {
  value = var.load_balancer_enabled == true ? module.task_alb[0].green_target_group_name : null
}