variable "load_balancer_certificate_arn" {
  description = "If using an existing ACM certificate this should contain the ARN of the certificate to link to the load balancer"
  type = string
  default = null
}

variable "load_balancer_certificate_name" {
  description = "Primary subject name to be used on the load balancer certificate. This is required if using a HTTPS listener"
  type = object({
    name = string
    hosted_zone_id = string
  })
  default = null
}

variable "load_balancer_certificate_alternate_names" {
  description = "Optional set of alternate subject names to be added to the load balancer certificate"
  type = set(object({
    name = string
    hosted_zone_id = string
  }))
  default = []
}

module "load_balancer_certificate" {
  count = var.load_balancer_listener_protocol == "https" && var.load_balancer_create == true && var.load_balancer_certificate_arn == null && var.load_balancer_certificate_name != null ? 1 : 0
  source = "git::https://github.com/TerraFlops/aws-acm-certificate.git?ref=v2.7"
  hosted_zone_id = var.load_balancer_certificate_name.hosted_zone_id
  domain_name = var.load_balancer_certificate_name.name
  subject_alternative_names = var.load_balancer_certificate_alternate_names
}
