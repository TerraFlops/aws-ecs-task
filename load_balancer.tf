# Create certificate for the load balancer
module "task_alb_certificate" {
  count = var.load_balancer_listener_protocol == "https" && var.load_balancer_enabled == true ? 1 : 0
  source = "git::https://github.com/TerraFlops/aws-acm-certificate.git?ref=v1.0"
  domain_name = var.load_balancer_certificate_subject_name
  hosted_zone_id = var.load_balancer_dns_record_hosted_zone_id
  subject_alternative_names = var.load_balancer_certificate_alternate_names
}

# Create load balancer
module "task_alb" {
  count = var.load_balancer_enabled == true ? 1 : 0
  source = "git::https://github.com/TerraFlops/aws-ecs-blue-green-load-balancer?ref=v1.0"
  name = var.container_name
  # Setup log bucket
  log_bucket = var.load_balancer_log_bucket
  log_bucket_create = true
  # Setup listener
  listener_port = var.load_balancer_listener_port
  listener_protocol = var.load_balancer_listener_protocol
  listener_certificate_arn = var.load_balancer_listener_protocol == "https" ? module.task_alb_certificate[0].acm_certificate_arn : null
  # Setup target
  target_type = "ip"
  target_port = var.load_balancer_target_port
  target_protocol = var.load_balancer_target_protocol
  deregistration_delay = var.load_balancer_deregistration_delay
  # Setup health check
  health_check_port = var.load_balancer_health_check_port
  health_check_url = var.load_balancer_health_check_url
  health_check_protocol = var.load_balancer_health_check_protocol
  health_check_response_codes = join(",", var.load_balancer_health_check_response_codes)
  health_check_timeout = var.load_balancer_health_check_timeout
  # Configure VPC settings
  vpc_id = var.load_balancer_vpc_id
  security_group_ids = var.load_balancer_security_group_ids
  subnet_ids = var.load_balancer_subnet_ids
}

# Create Route 53 record for the load balancer
resource "aws_route53_record" "task" {
  count = var.load_balancer_enabled == true ? 1 : 0
  name = var.load_balancer_dns_record_name
  zone_id = var.load_balancer_dns_record_hosted_zone_id
  type = "CNAME"
  allow_overwrite = true
  ttl = 60
  records = [
    module.task_alb[0].alb_dns_name
  ]
}