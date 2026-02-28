variable "project_name" {
  description = "Project name used in resource naming"
  type        = string
  default     = "golf-league"
}

variable "hosted_zone_name" {
  description = "The Route53 hosted zone domain (e.g. gillzhub.com)"
  type        = string
  default     = "gillzhub.com"
}

variable "region" {
  description = "AWS region for infrastructure"
  type        = string
  default     = "us-west-2"
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

variable "github_oauth_client_id" {
  description = "GitHub OAuth App client ID for super-admin authentication"
  type        = string
}

variable "github_oauth_client_secret" {
  description = "GitHub OAuth App client secret for super-admin authentication"
  type        = string
  sensitive   = true
}

variable "auth_signing_key" {
  description = "Secret key used to sign auth tokens (min 32 chars)"
  type        = string
  sensitive   = true
}

variable "allowed_github_login" {
  description = "GitHub username allowed to authenticate as superadmin"
  type        = string
  default     = "gillzj00"
}
