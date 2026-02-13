output "alb_dns" {
  description = "ALB DNS name"
  value       = aws_lb.app.dns_name
}

output "site_url" {
  description = "HTTPS URL for site"
  value       = "https://${var.domain_name}"
}

output "route53_nameservers" {
  description = "Nameservers for the Route53 zone (update your registrar with these)"
  value       = aws_route53_zone.primary.name_servers
}

output "instance_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.web.public_ip
}

output "certificate_validation_records" {
  description = "DNS records needed for ACM certificate validation"
  value = {
    for dvo in aws_acm_certificate.site_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }
}

output "budget_sns_topic_arn" {
  description = "ARN of the SNS topic for budget alert notifications"
  value       = aws_sns_topic.budget_alerts.arn
}

output "monthly_budget_name" {
  description = "Name of the monthly cost budget"
  value       = aws_budgets_budget.monthly.name
}

output "api_gateway_url" {
  description = "API Gateway HTTP API URL"
  value       = aws_apigatewayv2_api.guestbook.api_endpoint
}

output "api_custom_domain" {
  description = "Custom domain for the guestbook API"
  value       = "https://api.${var.domain_name}"
}

output "guestbook_table_name" {
  description = "DynamoDB table name for guestbook entries"
  value       = aws_dynamodb_table.guestbook.name
}

output "guestbook_lambda_function_name" {
  description = "Lambda function name for the guestbook API"
  value       = aws_lambda_function.guestbook_api.function_name
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID (needed for cache invalidation in deploy workflow)"
  value       = aws_cloudfront_distribution.site.id
}

output "site_bucket_name" {
  description = "S3 bucket name for SPA static files"
  value       = aws_s3_bucket.site.id
}