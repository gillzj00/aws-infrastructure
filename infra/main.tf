# Route53 zone
resource "aws_route53_zone" "primary" {
  name    = var.hosted_zone_name
  comment = "Route53 hosted zone for website managed by Terraform"

  tags = merge(
    var.tags,
    {
      Name        = var.hosted_zone_name
      Environment = var.environment
    }
  )
}

# DNS record for the website (CloudFront)
resource "aws_route53_record" "site_alias" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.site.domain_name
    zone_id                = aws_cloudfront_distribution.site.hosted_zone_id
    evaluate_target_health = false
  }
}

# DNS record for API Gateway custom domain
resource "aws_route53_record" "api_alias" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = "api.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_apigatewayv2_domain_name.api.domain_name_configuration[0].target_domain_name
    zone_id                = aws_apigatewayv2_domain_name.api.domain_name_configuration[0].hosted_zone_id
    evaluate_target_health = false
  }
}
