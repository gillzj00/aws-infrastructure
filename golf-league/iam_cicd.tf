# ──────────────────────────────────────────────
# GitHub Actions OIDC role for golf-sim-league repo CI/CD
# ──────────────────────────────────────────────
resource "aws_iam_role" "github_actions" {
  name = "github-actions-${var.project_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRoleWithWebIdentity"
      Effect = "Allow"
      Principal = {
        Federated = data.aws_iam_openid_connect_provider.github.arn
      }
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
        StringLike = {
          "token.actions.githubusercontent.com:sub" = "repo:gillzj00/golf-sim-league:*"
        }
      }
    }]
  })

  tags = merge(
    var.tags,
    {
      Name = "github-actions-${var.project_name}-role"
    }
  )
}

resource "aws_iam_role_policy" "github_actions" {
  name = "github-actions-${var.project_name}-policy"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # S3 deploy bucket: upload Lambda ZIP artifacts
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.deploy.arn,
          "${aws_s3_bucket.deploy.arn}/*"
        ]
      },
      {
        # Lambda deployment: update function code from S3
        Effect = "Allow"
        Action = [
          "lambda:UpdateFunctionCode",
          "lambda:GetFunction",
          "lambda:GetFunctionConfiguration"
        ]
        Resource = [aws_lambda_function.api.arn]
      },
      {
        # CloudFront cache invalidation after SPA deploys
        Effect = "Allow"
        Action = [
          "cloudfront:CreateInvalidation",
          "cloudfront:GetInvalidation"
        ]
        Resource = [aws_cloudfront_distribution.site.arn]
      },
      {
        # S3 site bucket: upload/delete SPA build artifacts
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:DeleteObject"
        ]
        Resource = [
          aws_s3_bucket.site.arn,
          "${aws_s3_bucket.site.arn}/*"
        ]
      }
    ]
  })
}
