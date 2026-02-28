# ──────────────────────────────────────────────
# CloudFront Origin Access Control
# ──────────────────────────────────────────────
resource "aws_cloudfront_origin_access_control" "site" {
  name                              = "${var.project_name}-site-oac"
  description                       = "OAC for golf league SPA"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# S3 bucket policy — only CloudFront can read objects
resource "aws_s3_bucket_policy" "site" {
  bucket = aws_s3_bucket.site.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "AllowCloudFrontServicePrincipal"
      Effect = "Allow"
      Principal = {
        Service = "cloudfront.amazonaws.com"
      }
      Action   = "s3:GetObject"
      Resource = "${aws_s3_bucket.site.arn}/*"
      Condition = {
        StringEquals = {
          "AWS:SourceArn" = aws_cloudfront_distribution.site.arn
        }
      }
    }]
  })
}

# ──────────────────────────────────────────────
# CloudFront Distribution (wildcard *.gillzhub.com)
# ──────────────────────────────────────────────
resource "aws_cloudfront_distribution" "site" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Golf League SPA (wildcard *.${var.hosted_zone_name})"
  default_root_object = "index.html"
  aliases             = ["*.${var.hosted_zone_name}"]
  price_class         = "PriceClass_100" # US + Europe only (cheapest tier)

  origin {
    domain_name              = aws_s3_bucket.site.bucket_regional_domain_name
    origin_id                = "S3-${aws_s3_bucket.site.id}"
    origin_access_control_id = aws_cloudfront_origin_access_control.site.id
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-${aws_s3_bucket.site.id}"
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 86400
    max_ttl     = 31536000
    compress    = true # Gzip/Brotli for JS/CSS/HTML
  }

  # SPA routing: S3 returns 403 for missing keys (bucket is private).
  # CloudFront intercepts and returns index.html so the SPA router can handle the route.
  custom_error_response {
    error_code            = 403
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 10
  }

  custom_error_response {
    error_code            = 404
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 10
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.wildcard_cert.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  depends_on = [aws_acm_certificate_validation.wildcard_cert_validation]

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-cloudfront"
      Environment = var.environment
    }
  )
}
