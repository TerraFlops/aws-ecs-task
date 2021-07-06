variable "ecs_task_scaling_enabled" {
  description = "Boolean flag, if true scaling rules will be created"
  type = bool
  default = false
}

variable "ecs_task_scaling_minimum" {
  description = "Minimum number of tasks"
  type = number
  default = 1
}

variable "ecs_task_scaling_maximum" {
  description = "Maximum number of tasks"
  type = number
  default = 1
}

variable "ecs_task_cpu_scaling_target" {
  type = number
  default = 50
}

resource "aws_appautoscaling_target" "scaling_target" {
  depends_on = [ aws_ecs_service.task ]
  count = var.ecs_task_scaling_enabled == true ? 1 : 0
  max_capacity = var.ecs_task_scaling_maximum
  min_capacity = var.ecs_task_scaling_minimum
  resource_id = "service/${var.ecs_cluster_name}/${local.ecs_task_name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace = "ecs"
}

resource "aws_appautoscaling_policy" "scaling_policy" {
  depends_on = [ aws_ecs_service.task ]
  count = var.ecs_task_scaling_enabled == true ? 1 : 0
  name = "${local.application_name_snake}${var.ecs_cluster_name}${local.ecs_task_name}CpuTargetTracking"
  policy_type = "TargetTrackingScaling"
  resource_id = aws_appautoscaling_target.scaling_target[0].resource_id
  scalable_dimension = aws_appautoscaling_target.scaling_target[0].scalable_dimension
  service_namespace = aws_appautoscaling_target.scaling_target[0].service_namespace
  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = var.ecs_task_cpu_scaling_target
  }
}
