variable "domain_name" {
  description = "Fully-qualified domain name for the site (e.g. forfun.gillzhub.com)"
  type        = string
  default     = "forfun.gillzhub.com"
}

variable "hosted_zone_name" {
  description = "The Route53 hosted zone domain (e.g. gillzhub.com)"
  type        = string
  default     = "gillzhub.com"
}

variable "region" {
  description = "AWS region for ALB and instance"
  type        = string
  default     = "us-west-2"
}

variable "instance_type" {
  description = "EC2 instance type for the Windows server"
  type        = string
  default     = "t3.small"
}

variable "environment" {
  description = "Environment name used for resource tagging"
  type        = string
  default     = "dev"
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "notification_email" {
  description = "Email address for AWS Budget spending alert notifications"
  type        = string
  sensitive   = true
}