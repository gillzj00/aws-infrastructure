# ──────────────────────────────────────────────
# IAM Role for Lambda execution
# ──────────────────────────────────────────────
resource "aws_iam_role" "lambda" {
  name = "${var.project_name}-lambda"

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
      Name        = "${var.project_name}-lambda-role"
      Environment = var.environment
    }
  )
}

# CloudWatch Logs — Lambda needs this to write logs
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# DynamoDB access — scoped to golf league tables and their GSIs
resource "aws_iam_role_policy" "lambda_dynamodb" {
  name = "${var.project_name}-dynamodb-access"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:DeleteItem",
        "dynamodb:UpdateItem",
        "dynamodb:Scan",
        "dynamodb:Query"
      ]
      Resource = [
        aws_dynamodb_table.leagues.arn,
        "${aws_dynamodb_table.leagues.arn}/index/*",
        aws_dynamodb_table.players.arn,
        "${aws_dynamodb_table.players.arn}/index/*",
        aws_dynamodb_table.rounds.arn,
        "${aws_dynamodb_table.rounds.arn}/index/*",
        aws_dynamodb_table.scores.arn,
        "${aws_dynamodb_table.scores.arn}/index/*",
      ]
    }]
  })
}

# SSM Parameter Store access — read OAuth + auth secrets at runtime
resource "aws_iam_role_policy" "lambda_ssm" {
  name = "${var.project_name}-ssm-access"
  role = aws_iam_role.lambda.id

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
          aws_ssm_parameter.auth_signing_key.arn,
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

# Bedrock access — invoke Nova Micro for golf quote generation
resource "aws_iam_role_policy" "lambda_bedrock" {
  name = "${var.project_name}-bedrock-access"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = ["bedrock:InvokeModel"]
      Resource = [
        "arn:aws:bedrock:${var.region}::foundation-model/amazon.nova-micro-v1:0",
        "arn:aws:bedrock:${var.region}:${data.aws_caller_identity.current.account_id}:inference-profile/us.amazon.nova-micro-v1:0"
      ]
    }]
  })
}

# ──────────────────────────────────────────────
# CloudWatch Log Group (explicit so Terraform manages retention)
# ──────────────────────────────────────────────
resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.project_name}-api"
  retention_in_days = 14

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-lambda-logs"
      Environment = var.environment
    }
  )
}

# ──────────────────────────────────────────────
# Placeholder deployment package — CI/CD replaces this with the real build
# ──────────────────────────────────────────────
data "archive_file" "lambda_placeholder" {
  type        = "zip"
  output_path = "${path.module}/.placeholder.zip"

  source {
    content  = "#!/bin/sh\nexit 0"
    filename = "bootstrap"
  }
}

# ──────────────────────────────────────────────
# Lambda Function (Go on ARM64/Graviton)
# ──────────────────────────────────────────────
resource "aws_lambda_function" "api" {
  function_name = "${var.project_name}-api"
  description   = "Golf League API (Go)"
  role          = aws_iam_role.lambda.arn
  handler       = "bootstrap"       # Go binary compiled for Lambda
  runtime       = "provided.al2023" # Custom runtime for Go
  architectures = ["arm64"]         # Graviton — cheaper + faster for Go
  timeout       = 15                # OAuth callback + Bedrock calls make external HTTP calls
  memory_size   = 256               # More memory = proportionally more CPU

  # Placeholder for initial creation — CI/CD deploys the real build via S3
  filename         = data.archive_file.lambda_placeholder.output_path
  source_code_hash = data.archive_file.lambda_placeholder.output_base64sha256

  lifecycle {
    ignore_changes = [filename, source_code_hash, s3_bucket, s3_key]
  }

  environment {
    variables = {
      LEAGUES_TABLE_NAME       = aws_dynamodb_table.leagues.name
      PLAYERS_TABLE_NAME       = aws_dynamodb_table.players.name
      ROUNDS_TABLE_NAME        = aws_dynamodb_table.rounds.name
      SCORES_TABLE_NAME        = aws_dynamodb_table.scores.name
      SSM_GITHUB_CLIENT_ID     = aws_ssm_parameter.github_oauth_client_id.name
      SSM_GITHUB_CLIENT_SECRET = aws_ssm_parameter.github_oauth_client_secret.name
      SSM_AUTH_SIGNING_KEY     = aws_ssm_parameter.auth_signing_key.name
      API_DOMAIN               = "api.golf.${var.hosted_zone_name}"
      HOSTED_ZONE_NAME         = var.hosted_zone_name
      ALLOWED_GITHUB_LOGIN     = var.allowed_github_login
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.lambda,
    aws_iam_role_policy_attachment.lambda_logs,
  ]

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-api"
      Environment = var.environment
    }
  )
}
