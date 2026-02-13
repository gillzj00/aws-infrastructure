# S3 bucket for website deployments
resource "aws_s3_bucket" "deploy" {
  bucket = "deploy-${var.domain_name}-${data.aws_caller_identity.current.account_id}"

  tags = merge(
    var.tags,
    {
      Name = "Website Deployment Bucket"
    }
  )
}

# Block all public access to the bucket
resource "aws_s3_bucket_public_access_block" "deploy" {
  bucket = aws_s3_bucket.deploy.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Explicitly declare SSE — S3 encrypts by default since Jan 2023, but enterprise
# policy expects this to be declared in code so auditors can verify at a glance.
resource "aws_s3_bucket_server_side_encryption_configuration" "deploy" {
  bucket = aws_s3_bucket.deploy.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

# Enable versioning for the bucket
resource "aws_s3_bucket_versioning" "deploy" {
  bucket = aws_s3_bucket.deploy.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Output the bucket name for use in GitHub Actions
output "deploy_bucket_name" {
  value       = aws_s3_bucket.deploy.id
  description = "Name of the S3 bucket used for website deployments"
}