variable "load_balancer_cname" {
  description = "Optional vanity DNS CNAME record to be created pointing to the load balancer DNS name"
  type = string
  default = null
}

variable "load_balancer_cname_hosted_zone_id" {
  description = "The Route53 Hosted Zone in which the vanity DNS CNAME will be created"
  type = string
  default = null
}

variable "load_balancer_cname_allow_overwrite" {
  description = "Boolean flag, if true the DNS CNAME can overwrite existing records"
  type = bool
  default = true
}

variable "load_balancer_cname_ttl" {
  type = number
  default = 60
}

resource "aws_route53_record" "load_balancer_cname" {
  count = var.load_balancer_create == true && var.load_balancer_cname_hosted_zone_id != null && var.load_balancer_cname != null ? 1 : 0
  name = var.load_balancer_cname
  type = "CNAME"
  zone_id = var.load_balancer_cname_hosted_zone_id
  allow_overwrite = var.load_balancer_cname_allow_overwrite
  ttl = var.load_balancer_cname_ttl
  records = [ aws_lb.application[0].dns_name ]
}
