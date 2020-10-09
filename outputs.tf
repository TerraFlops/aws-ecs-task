output "ecs_task_name" {
  description = "ECS task name"
  value = local.ecs_task_name
}

output "ecs_task_family" {
  description = "ECS task family"
  value = local.ecs_task_name
}

output "ecs_task_iam_role_arn" {
  description = "ARN of the ECS task role"
  value = var.ecs_task_role_name_create == true ? module.ecs_task_iam_role[0].iam_role_arn : data.aws_iam_role.ecs_task_iam_role[0].arn
}

output "ecs_task_iam_role_name" {
  description = "Name of the ECS task role"
  value = var.ecs_task_role_name_create == true ? module.ecs_task_iam_role[0].iam_role_name : data.aws_iam_role.ecs_task_iam_role[0].name
}

output "ecs_execution_iam_role_arn" {
  description = "ARN of the ECS execution role"
  value = var.ecs_execution_role_name_create == true ? module.ecs_execution_iam_role[0].iam_role_arn : data.aws_iam_role.ecs_execution_iam_role[0].arn
}

output "ecs_execution_iam_role_name" {
  description = "Name of the ECS execution role"
  value = var.ecs_execution_role_name_create == true ? module.ecs_execution_iam_role[0].iam_role_name : data.aws_iam_role.ecs_execution_iam_role[0].name
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value = var.ecs_cluster_name
}

output "ecs_service_id" {
  description = "ECS service ID"
  value = aws_ecs_service.task.id
}

output "ecs_service_name" {
  description = "ECS service name"
  value = aws_ecs_service.task.name
}

output "alb_arn" {
  description = "If an ALB was created this will contain the ARN of the load balancer"
  value = var.alb_enabled == true ? module.task_alb[0].alb_arn : null
}

output "alb_dns_name" {
  description = "If an ALB was created this will contain the DNS name"
  value = var.alb_enabled == true ? module.task_alb[0].alb_dns_name : null
}

output "alb_certificate_arn" {
  description = "If an ALB was created this will contain the ARN of certificate linked to it"
  value = local.alb_certificate_arn
}

output "alb_listener_arn" {
  description = "If an ALB was created this will contain the ARN of the listener"
  value = var.alb_enabled == true ? module.task_alb[0].alb_listener_arn : null
}

output "blue_target_group_arn" {
  description = "If an ALB was created this will contain the ARN of the blue target group"
  value = var.alb_enabled == true ? module.task_alb[0].blue_target_group_arn : null
}

output "blue_target_group_name" {
  description = "If an ALB was created this will contain the name of the green target group"
  value = var.alb_enabled == true ? module.task_alb[0].blue_target_group_name : null
}

output "green_target_group_arn" {
  description = "If an ALB was created this will contain the ARN of the green target group"
  value = var.alb_enabled == true ? module.task_alb[0].green_target_group_arn : null
}

output "green_target_group_name" {
  description = "If an ALB was created this will contain the name of the green target group"
  value = var.alb_enabled == true ? module.task_alb[0].green_target_group_name : null
}