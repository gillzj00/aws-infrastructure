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

# Delegation for whack.gillzhub.com — the Pod Whack-A-Mole cluster.
#
# That project builds into its own AWS account so that tearing
# its cluster down cannot reach anything in this one. It therefore cannot write
# records into this zone, and should not be able to. Instead it owns a hosted
# zone of its own for whack.gillzhub.com, and this NS record is the only thing
# here that points at it.
#
# Note the interaction with the *.gillzhub.com wildcard: whack.gillzhub.com
# resolves to CloudFront via that wildcard today. An NS
# record creates a zone cut, and per RFC 4592 a wildcard never synthesises for
# a name at or below one, so this delegation takes over cleanly and the
# wildcard keeps serving every other undefined subdomain.
#
# The nameservers are literal because they are assigned by Route53 when the
# delegated zone is created. If that zone is ever destroyed and recreated it
# gets a new set and these must be updated to match, which is why the other
# project treats its zone as create-once and keeps it out of its own Terraform.
resource "aws_route53_record" "whack_delegation" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = "whack.${var.hosted_zone_name}"
  type    = "NS"
  ttl     = 172800

  records = [
    "ns-276.awsdns-34.com.",
    "ns-822.awsdns-38.net.",
    "ns-1170.awsdns-18.org.",
    "ns-1713.awsdns-22.co.uk.",
  ]
}
