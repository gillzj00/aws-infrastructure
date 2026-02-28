data "aws_caller_identity" "current" {}

# Reference the existing Route53 zone (owned by infra/)
data "aws_route53_zone" "primary" {
  name = var.hosted_zone_name
}

# Reference the existing OIDC provider (owned by infra/)
data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}
