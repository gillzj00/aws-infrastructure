# Wildcard DNS record — catches all *.gillzhub.com subdomains not explicitly defined.
# forfun.gillzhub.com and api.forfun.gillzhub.com have explicit records (in infra/)
# that take precedence over this wildcard per standard DNS resolution rules.
resource "aws_route53_record" "wildcard_alias" {
  zone_id = data.aws_route53_zone.primary.zone_id
  name    = "*.${var.hosted_zone_name}"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.site.domain_name
    zone_id                = aws_cloudfront_distribution.site.hosted_zone_id
    evaluate_target_health = false
  }
}

# API Gateway DNS record
resource "aws_route53_record" "api_alias" {
  zone_id = data.aws_route53_zone.primary.zone_id
  name    = "api.golf.${var.hosted_zone_name}"
  type    = "A"

  alias {
    name                   = aws_apigatewayv2_domain_name.api.domain_name_configuration[0].target_domain_name
    zone_id                = aws_apigatewayv2_domain_name.api.domain_name_configuration[0].hosted_zone_id
    evaluate_target_health = false
  }
}
