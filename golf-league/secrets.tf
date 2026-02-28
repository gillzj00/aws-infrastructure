# SSM Parameter Store for GitHub OAuth + auth signing secrets
# Using Parameter Store (not Secrets Manager) — SecureString is free vs $0.40/secret/month.

resource "aws_ssm_parameter" "github_oauth_client_id" {
  name        = "/${var.environment}/${var.project_name}/github-oauth-client-id"
  description = "GitHub OAuth App client ID for golf league super-admin auth"
  type        = "String" # Not secret — client ID is public (sent to browser in OAuth redirect)
  value       = var.github_oauth_client_id

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-github-oauth-client-id"
      Environment = var.environment
    }
  )
}

resource "aws_ssm_parameter" "github_oauth_client_secret" {
  name        = "/${var.environment}/${var.project_name}/github-oauth-client-secret"
  description = "GitHub OAuth App client secret for golf league super-admin auth"
  type        = "SecureString" # Encrypted at rest with default KMS key
  value       = var.github_oauth_client_secret

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-github-oauth-client-secret"
      Environment = var.environment
    }
  )
}

resource "aws_ssm_parameter" "auth_signing_key" {
  name        = "/${var.environment}/${var.project_name}/auth-signing-key"
  description = "Secret key for signing and verifying auth tokens"
  type        = "SecureString"
  value       = var.auth_signing_key

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-auth-signing-key"
      Environment = var.environment
    }
  )
}
