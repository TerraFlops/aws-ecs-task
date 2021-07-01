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

variable "ecs_task_scaling_cpu_threshold_up" {
  description = "CPU scaling threshold"
  type = number
  default = 80
}

variable "ecs_task_scaling_cpu_up_adjustment" {
  description = "Number of tasks to scale up"
  type = number
  default = 1
}

variable "ecs_task_scaling_cpu_evaluation_periods" {
  description = "CPU scaling number of evaluation periods"
  type = number
  default = 1
}

variable "ecs_task_cpu_scaling_target" {
  type = number
  default = 50
}

variable "ecs_task_scaling_cpu_comparison_up" {
  description = "CPU scaling comparison"
  type = string
  default = "GreaterThanOrEqualToThreshold"
}

variable "ecs_task_scaling_cpu_statistic" {
  description = "CPU scaling statistic"
  type = string
  default = "Average"
}

variable "ecs_task_scaling_cpu_period" {
  description = "CPU scaling measurement period"
  type = number
  default = 60
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
  name = "${var.ecs_cluster_name}${local.ecs_task_name}CpuScaleDown"
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
