#################################################################################
# ROUTE53
#################################################################################
resource "aws_route53_record" "record" {
  zone_id = var.route53_zone_id
  name    = var.frontend_domain
  type    = "A"
  alias {
    name                   = var.lb_dns_name
    zone_id                = var.lb_zone_id
    evaluate_target_health = var.evaluate_target_health
  }
}