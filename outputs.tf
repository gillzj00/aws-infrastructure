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