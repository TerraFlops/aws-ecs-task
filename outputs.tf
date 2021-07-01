output "ecs_task_name" {
  value = local.ecs_task_name
}

output "ecs_task_family" {
  value = aws_ecs_task_definition.task.family
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

output "iam_role_task_arn" {
  description = "ARN of the ECS task role"
  value = aws_iam_role.iam_role_task.arn
}

output "iam_role_task_name" {
  description = "Name of the ECS task role"
  value = aws_iam_role.iam_role_task.name
}

output "iam_role_execution_arn" {
  description = "ARN of the ECS execution role"
  value = aws_iam_role.iam_role_execution.arn
}

output "iam_role_execution_name" {
  description = "Name of the ECS execution role"
  value = aws_iam_role.iam_role_execution.name
}

output "load_balancer_arn" {
  value = var.load_balancer_create == false ? null : aws_lb.application[0].arn
}

output "load_balancer_id" {
  value = var.load_balancer_create == false ? null : aws_lb.application[0].id
}

output "load_balancer_dns_name" {
  value = var.load_balancer_create == false ? null : aws_lb.application[0].dns_name
}

output "load_balancer_certificate_arn" {
  value = var.load_balancer_listener_protocol == "https" && var.load_balancer_create == true && var.load_balancer_certificate_arn == null && var.load_balancer_certificate_name != null ? module.load_balancer_certificate[0].acm_certificate_arn : null
}

output "load_balancer_listener_arn" {
  value = var.load_balancer_create == false ? null : aws_lb.application[0].arn
}

output "target_group_arn" {
  value = var.load_balancer_create == false ? null : aws_lb_target_group.ecs_task.arn
}

output "target_group_name" {
  value = var.load_balancer_create == false ? null : aws_lb_target_group.ecs_task.name
}
