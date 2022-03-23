variable "load_balancer_create" {
  description = "Boolean flag, if true a load balancer will be created and linked to the task (defaults to False)"
  type = bool
  default = false
}

variable "load_balancer_internal" {
  description = "Boolean flag, if true the load balancer will only be exposed to VPC traffic (defaults to False)"
  type = bool
  default = false
}

variable "load_balancer_security_group_ids" {
  description = "Set of AWS security group IDs that will be added to the load balancer"
  type = set(string)
  default = []
}

variable "load_balancer_subnet_ids" {
  description = "Set of AWS subnet IDs into which the load balancer will be created"
  type = set(string)
  default = []
}

variable "load_balancer_vpc_id" {
  description = "The AWS VPC ID into which the load balancer will be created"
  type = string
  default = null
}

variable "load_balancer_log_bucket" {
  description = "The S3 bucket that will be used for load balancer logs"
  type = string
  default = null
}

variable "load_balancer_listener_port" {
  description = "The port the load balancer will use when listening for public traffic. Defaults to 443"
  type = number
  default = 443
}

variable "load_balancer_listener_protocol" {
  description = "The protocol the load balancer will use when listening for public traffic. Defaults to HTTPS"
  type = string
  default = "https"
}

variable "load_balancer_target_type" {
  description = "The target type for the ALB. Defaults to 'ip'"
  type = string
  default = "ip"
}

variable "load_balancer_target_protocol" {
  description = "The protocol the load balancer will when passing traffic to the target container. Defaults to HTTP"
  type = string
  default = "http"
}

variable "load_balancer_deregistration_delay" {
  description = "The number of seconds to wait before de-registering instance from the load balancer. Defaults to 45 seconds"
  type = number
  default = 45
}

variable "load_balancer_health_check_enabled" {
  type = bool
  default = true
}

variable "load_balancer_health_check_port" {
  description = "The port to use when performing the load balancer health check"
  type = number
  default = 8080
}

variable "load_balancer_health_check_url" {
  description = "The URL to use when performing load balancer health check. If none supplied defaults to '/ping'"
  type = string
  default = "/ping"
}

variable "load_balancer_health_check_protocol" {
  description = "Protocol to use when performing the health check. If none supplied defaults to HTTP"
  type = string
  default = "http"
}

variable "load_balancer_health_check_timeout" {
  description = "Number of seconds to wait for expected response code before reporting a timeout"
  type = number
  default = 5
}

variable "load_balancer_health_check_response_codes" {
  description = "Set of HTTP response codes that are considered a passing health check. If none supplied will default to HTTP 200 only"
  type = set(number)
  default = [200]
}

variable "load_balancer_ssl_policy" {
  description = "SSL negotiation policy that will be used by the load balancer (defaults to ELBSecurityPolicy-TLS-1-2-Ext-2018-06)"
  type = string
  default = "ELBSecurityPolicy-TLS-1-2-Ext-2018-06"
}

variable "audit_log_bucket" {
  description = "Log bucket name that will be used to store audit logs for the load balancer logs"
  type = string
  default = null
}

variable "audit_log_bucket_prefix" {
  description = "S3 prefix for the load balancer log buckets audit logs"
  type = string
  default = null
}

variable "waf_arn" {
  description = "ARN of WAF to attach to ALB"
  type = string
  default = ""
}

locals {
  alb_health_check_response_codes = join(",", var.load_balancer_health_check_response_codes)
  alb_log_bucket_create = var.load_balancer_log_bucket != null
  listener_certificate_arn = var.load_balancer_listener_protocol == "https" ? var.load_balancer_certificate_arn == null ? (var.load_balancer_listener_protocol == "https" && var.load_balancer_create == true && var.load_balancer_certificate_arn == null ? module.load_balancer_certificate[0].acm_certificate_arn : null) : var.load_balancer_certificate_arn : null
  container_name = join("", [ for element in split("_", replace(local.ecs_task_name, "-", "_")): title(lower(element)) ])

}

resource "aws_s3_bucket" "audit_log_bucket" {
  count = var.load_balancer_create && local.alb_log_bucket_create == true ? 1 : 0
  bucket = var.load_balancer_log_bucket
  versioning {
    enabled = true
  }
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
  policy = data.aws_iam_policy_document.log_bucket[0].json
  dynamic "logging" {
    for_each = var.audit_log_bucket == null ? {} : tomap({
      logging = {
        target_bucket = var.audit_log_bucket
        target_prefix = var.audit_log_bucket_prefix
      }
    })
    content {
      target_bucket = logging.value["target_bucket"]
      target_prefix = logging.value["target_prefix"]
    }
  }
}

resource "aws_s3_bucket_public_access_block" "log_bucket" {
  count = local.alb_log_bucket_create == true ? 1 : 0
  bucket = aws_s3_bucket.audit_log_bucket[0].bucket
  block_public_acls = true
  block_public_policy = true
  ignore_public_acls = true
  restrict_public_buckets = true
}

# Setup bucket policy allowing ALB to write logs (https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-access-logs.html)
data "aws_iam_policy_document" "log_bucket" {
  count = var.load_balancer_create ? 1 : 0
  version = "2012-10-17"
  statement {
    effect = "Allow"
    actions = ["s3:PutObject"]
    resources = ["arn:aws:s3:::${var.load_balancer_log_bucket}/${local.container_name}/AWSLogs/${data.aws_caller_identity.default.account_id}/*"]
    principals {
      identifiers = ["arn:aws:iam::783225319266:root"]
      type = "AWS"
    }
  }
  statement {
    effect = "Allow"
    actions = ["s3:PutObject"]
    resources = ["arn:aws:s3:::${var.load_balancer_log_bucket}/${local.container_name}/AWSLogs/${data.aws_caller_identity.default.account_id}/*"]
    principals {
      identifiers = ["delivery.logs.amazonaws.com"]
      type = "Service"
    }
    condition {
      test = "StringEquals"
      values = ["bucket-owner-full-control"]
      variable = "s3:x-amz-acl"
    }
  }
  statement {
    effect = "Allow"
    actions = ["s3:GetBucketAcl"]
    resources = ["arn:aws:s3:::${var.load_balancer_log_bucket}"]
    principals {
      identifiers = ["delivery.logs.amazonaws.com"]
      type = "Service"
    }
  }
  statement {
    sid = "DenyInsecureCommunications"
    effect = "Deny"
    principals {
      identifiers = ["*"]
      type = "AWS"
    }
    actions = ["s3:*"]
    resources = ["arn:aws:s3:::${var.load_balancer_log_bucket}", "arn:aws:s3:::${var.load_balancer_log_bucket}/*"]
    condition {
      test = "Bool"
      values = ["false"]
      variable = "aws:SecureTransport"
    }
  }
}

# Create application load balancer
resource "aws_lb" "application" {
  count = var.load_balancer_create ? 1 : 0
  name = "${local.application_name_snake}${local.container_name}"
  internal = var.load_balancer_internal
  load_balancer_type = "application"
  enable_deletion_protection = false
  drop_invalid_header_fields = true
  security_groups = var.load_balancer_security_group_ids
  subnets = var.load_balancer_subnet_ids
  access_logs {
    bucket = aws_s3_bucket.audit_log_bucket[0].bucket
    prefix = local.container_name
    enabled = true
  }
  tags = merge(var.ecs_task_tags, {
    Name = local.container_name
  })
}

resource "aws_wafv2_web_acl_association" "attach_waf" {
  count = var.waf_arn == "" ? 0 : 1
  resource_arn = aws_lb.application.arn
  web_acl_arn  = var.waf_arn
}

resource "aws_lb_target_group" "ecs_task" {
  count = var.load_balancer_create ? 1 : 0
  name = "${local.application_name_snake}${local.container_name}"
  port = var.load_balancer_target_port
  protocol = upper(var.load_balancer_target_protocol)
  target_type = var.load_balancer_target_type
  vpc_id = var.load_balancer_vpc_id
  deregistration_delay = var.load_balancer_deregistration_delay
  dynamic "health_check" {
    for_each = var.load_balancer_health_check_enabled == false ? {} : tomap({
      health_check = {
        path = var.load_balancer_health_check_url
        port = var.load_balancer_health_check_port
        matcher = join(",", var.load_balancer_health_check_response_codes)
        timeout = var.load_balancer_health_check_timeout
        protocol = upper(var.load_balancer_health_check_protocol)
      }
    })
    content {
      path = health_check.value["path"]
      port = health_check.value["port"]
      matcher = health_check.value["matcher"]
      timeout = health_check.value["timeout"]
      protocol = health_check.value["protocol"]
    }
  }
  tags = merge(var.ecs_task_tags, {
    Name = local.container_name
  })
}

resource "aws_lb_listener" "alb_listener" {
  count = var.load_balancer_create ? 1 : 0
  load_balancer_arn = aws_lb.application[0].arn
  port = var.load_balancer_listener_port
  protocol = upper(var.load_balancer_listener_protocol)
  certificate_arn = upper(var.load_balancer_listener_protocol) == "HTTPS" ? module.load_balancer_certificate[0].acm_certificate_arn : null
  ssl_policy = upper(var.load_balancer_listener_protocol) == "HTTPS" ? var.load_balancer_ssl_policy : null
  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.ecs_task[0].arn
  }
}
