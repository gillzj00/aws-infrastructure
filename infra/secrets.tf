# SSM Parameter Store for GitHub OAuth + JWT secrets
# Using Parameter Store (not Secrets Manager) for consistency with existing
# budget.tf pattern and because SecureString is free vs $0.40/secret/month.

resource "aws_ssm_parameter" "github_oauth_client_id" {
  name        = "/${var.environment}/guestbook/github-oauth-client-id"
  description = "GitHub OAuth App client ID for guestbook authentication"
  type        = "String" # Not secret — client ID is public (sent to browser in OAuth redirect)
  value       = var.github_oauth_client_id

  tags = merge(
    var.tags,
    {
      Name        = "${var.domain_name}-github-oauth-client-id"
      Environment = var.environment
    }
  )
}

resource "aws_ssm_parameter" "github_oauth_client_secret" {
  name        = "/${var.environment}/guestbook/github-oauth-client-secret"
  description = "GitHub OAuth App client secret for guestbook authentication"
  type        = "SecureString" # Encrypted at rest with default KMS key
  value       = var.github_oauth_client_secret

  tags = merge(
    var.tags,
    {
      Name        = "${var.domain_name}-github-oauth-client-secret"
      Environment = var.environment
    }
  )
}

resource "aws_ssm_parameter" "jwt_signing_key" {
  name        = "/${var.environment}/guestbook/jwt-signing-key"
  description = "Secret key used to sign and verify JWT tokens for guestbook sessions"
  type        = "SecureString"
  value       = var.jwt_signing_key

  tags = merge(
    var.tags,
    {
      Name        = "${var.domain_name}-jwt-signing-key"
      Environment = var.environment
    }
  )
}
