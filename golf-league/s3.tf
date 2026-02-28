# ──────────────────────────────────────────────
# S3 Bucket for Lambda deployment artifacts
# ──────────────────────────────────────────────
resource "aws_s3_bucket" "deploy" {
  bucket = "deploy-${var.project_name}-${data.aws_caller_identity.current.account_id}"

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-deploy-bucket"
    }
  )
}

resource "aws_s3_bucket_public_access_block" "deploy" {
  bucket = aws_s3_bucket.deploy.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "deploy" {
  bucket = aws_s3_bucket.deploy.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_versioning" "deploy" {
  bucket = aws_s3_bucket.deploy.id
  versioning_configuration {
    status = "Enabled"
  }
}

# ──────────────────────────────────────────────
# S3 Bucket for SPA static hosting (served via CloudFront)
# ──────────────────────────────────────────────
resource "aws_s3_bucket" "site" {
  bucket = "site-${var.project_name}-${data.aws_caller_identity.current.account_id}"

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-site"
      Environment = var.environment
    }
  )
}

resource "aws_s3_bucket_public_access_block" "site" {
  bucket = aws_s3_bucket.site.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# AES256 (not KMS) — CloudFront OAC can read AES256 without extra KMS permissions
resource "aws_s3_bucket_server_side_encryption_configuration" "site" {
  bucket = aws_s3_bucket.site.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
