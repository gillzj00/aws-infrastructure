# ──────────────────────────────────────────────
# IAM Role for Lambda execution
# ──────────────────────────────────────────────
resource "aws_iam_role" "guestbook_lambda" {
  name = "${replace(var.domain_name, ".", "-")}-guestbook-lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })

  tags = merge(
    var.tags,
    {
      Name        = "${var.domain_name}-guestbook-lambda-role"
      Environment = var.environment
    }
  )
}

# CloudWatch Logs — Lambda needs this to write logs
resource "aws_iam_role_policy_attachment" "guestbook_lambda_logs" {
  role       = aws_iam_role.guestbook_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# DynamoDB access — scoped to the guestbook table only
resource "aws_iam_role_policy" "guestbook_lambda_dynamodb" {
  name = "guestbook-dynamodb-access"
  role = aws_iam_role.guestbook_lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:Scan",
        "dynamodb:Query"
      ]
      Resource = [aws_dynamodb_table.guestbook.arn]
    }]
  })
}

# SSM Parameter Store access — read OAuth + JWT secrets at runtime
resource "aws_iam_role_policy" "guestbook_lambda_ssm" {
  name = "guestbook-ssm-access"
  role = aws_iam_role.guestbook_lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters"
        ]
        Resource = [
          aws_ssm_parameter.github_oauth_client_id.arn,
          aws_ssm_parameter.github_oauth_client_secret.arn,
          aws_ssm_parameter.jwt_signing_key.arn
        ]
      },
      {
        # SecureString parameters need KMS Decrypt for the default aws/ssm key
        Effect   = "Allow"
        Action   = ["kms:Decrypt"]
        Resource = ["*"]
      }
    ]
  })
}

# ──────────────────────────────────────────────
# CloudWatch Log Group (explicit so Terraform manages retention)
# ──────────────────────────────────────────────
resource "aws_cloudwatch_log_group" "guestbook_lambda" {
  name              = "/aws/lambda/${replace(var.domain_name, ".", "-")}-guestbook-api"
  retention_in_days = 14

  tags = merge(
    var.tags,
    {
      Name        = "${var.domain_name}-guestbook-lambda-logs"
      Environment = var.environment
    }
  )
}

# ──────────────────────────────────────────────
# Lambda Function
# ──────────────────────────────────────────────
resource "aws_lambda_function" "guestbook_api" {
  function_name = "${replace(var.domain_name, ".", "-")}-guestbook-api"
  description   = "Guestbook API with GitHub OAuth authentication"
  role          = aws_iam_role.guestbook_lambda.arn
  handler       = "src/index.handler"
  runtime       = "nodejs22.x"
  timeout       = 10  # OAuth callback makes external HTTP calls to GitHub; 3s default is too short
  memory_size   = 256 # More memory = proportionally more CPU = faster cold starts

  # Source from S3 so CI/CD can update code independently of Terraform
  s3_bucket = aws_s3_bucket.deploy.id
  s3_key    = "lambda/guestbook-api.zip"

  environment {
    variables = {
      DYNAMODB_TABLE_NAME      = aws_dynamodb_table.guestbook.name
      SSM_GITHUB_CLIENT_ID     = aws_ssm_parameter.github_oauth_client_id.name
      SSM_GITHUB_CLIENT_SECRET = aws_ssm_parameter.github_oauth_client_secret.name
      SSM_JWT_SIGNING_KEY      = aws_ssm_parameter.jwt_signing_key.name
      FRONTEND_URL             = "https://${var.domain_name}"
      API_DOMAIN               = "api.${var.domain_name}"
      NODE_OPTIONS             = "--enable-source-maps"
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.guestbook_lambda,
    aws_iam_role_policy_attachment.guestbook_lambda_logs,
  ]

  tags = merge(
    var.tags,
    {
      Name        = "${var.domain_name}-guestbook-api"
      Environment = var.environment
    }
  )
}
