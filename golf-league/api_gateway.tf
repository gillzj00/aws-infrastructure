# ──────────────────────────────────────────────
# API Gateway HTTP API
# ──────────────────────────────────────────────
resource "aws_apigatewayv2_api" "api" {
  name          = "${var.project_name}-api"
  protocol_type = "HTTP"
  description   = "HTTP API for golf league backend"

  cors_configuration {
    allow_origins     = ["https://*.${var.hosted_zone_name}"]
    allow_methods     = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
    allow_headers     = ["Content-Type", "Authorization"]
    allow_credentials = true
    max_age           = 86400
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-api"
      Environment = var.environment
    }
  )
}

# ──────────────────────────────────────────────
# Lambda Integration
# ──────────────────────────────────────────────
resource "aws_apigatewayv2_integration" "lambda" {
  api_id                 = aws_apigatewayv2_api.api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.api.invoke_arn
  payload_format_version = "2.0"
}

# Catch-all route — Go handler does its own routing via http.ServeMux
resource "aws_apigatewayv2_route" "catch_all" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "$default"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

# ──────────────────────────────────────────────
# Stage (auto-deploy)
# ──────────────────────────────────────────────
resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.api.id
  name        = "$default"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway.arn
    format = jsonencode({
      requestId        = "$context.requestId"
      ip               = "$context.identity.sourceIp"
      requestTime      = "$context.requestTime"
      httpMethod       = "$context.httpMethod"
      routeKey         = "$context.routeKey"
      status           = "$context.status"
      protocol         = "$context.protocol"
      responseLength   = "$context.responseLength"
      integrationError = "$context.integrationErrorMessage"
    })
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-api-stage"
      Environment = var.environment
    }
  )
}

resource "aws_cloudwatch_log_group" "api_gateway" {
  name              = "/aws/apigateway/${var.project_name}-api"
  retention_in_days = 14

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-api-gateway-logs"
      Environment = var.environment
    }
  )
}

# ──────────────────────────────────────────────
# Lambda permission — allow API Gateway to invoke Lambda
# ──────────────────────────────────────────────
resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}

# ──────────────────────────────────────────────
# Custom Domain for API Gateway
# ──────────────────────────────────────────────
resource "aws_apigatewayv2_domain_name" "api" {
  domain_name = "api.golf.${var.hosted_zone_name}"

  domain_name_configuration {
    certificate_arn = aws_acm_certificate.api_cert.arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }

  depends_on = [aws_acm_certificate_validation.api_cert_validation]

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-api-domain"
      Environment = var.environment
    }
  )
}

resource "aws_apigatewayv2_api_mapping" "api" {
  api_id      = aws_apigatewayv2_api.api.id
  domain_name = aws_apigatewayv2_domain_name.api.id
  stage       = aws_apigatewayv2_stage.default.id
}
