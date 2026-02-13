# ──────────────────────────────────────────────
# API Gateway HTTP API
# ──────────────────────────────────────────────
resource "aws_apigatewayv2_api" "guestbook" {
  name          = "${replace(var.domain_name, ".", "-")}-guestbook-api"
  protocol_type = "HTTP"
  description   = "HTTP API for guestbook backend with GitHub OAuth"

  cors_configuration {
    allow_origins     = ["https://${var.domain_name}"]
    allow_methods     = ["GET", "POST", "DELETE", "OPTIONS"]
    allow_headers     = ["Content-Type", "Authorization"]
    allow_credentials = true # Required for cross-subdomain cookies
    max_age           = 86400
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.domain_name}-guestbook-api"
      Environment = var.environment
    }
  )
}

# ──────────────────────────────────────────────
# Lambda Integration (single integration for all routes)
# ──────────────────────────────────────────────
resource "aws_apigatewayv2_integration" "guestbook_lambda" {
  api_id                 = aws_apigatewayv2_api.guestbook.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.guestbook_api.invoke_arn
  payload_format_version = "2.0" # HTTP API native format (simpler event structure)
}

# ──────────────────────────────────────────────
# Routes — explicit routes let API Gateway validate requests before invoking Lambda
# ──────────────────────────────────────────────
resource "aws_apigatewayv2_route" "auth_login" {
  api_id    = aws_apigatewayv2_api.guestbook.id
  route_key = "GET /auth/login"
  target    = "integrations/${aws_apigatewayv2_integration.guestbook_lambda.id}"
}

resource "aws_apigatewayv2_route" "auth_callback" {
  api_id    = aws_apigatewayv2_api.guestbook.id
  route_key = "GET /auth/callback"
  target    = "integrations/${aws_apigatewayv2_integration.guestbook_lambda.id}"
}

resource "aws_apigatewayv2_route" "auth_me" {
  api_id    = aws_apigatewayv2_api.guestbook.id
  route_key = "GET /auth/me"
  target    = "integrations/${aws_apigatewayv2_integration.guestbook_lambda.id}"
}

resource "aws_apigatewayv2_route" "auth_logout" {
  api_id    = aws_apigatewayv2_api.guestbook.id
  route_key = "POST /auth/logout"
  target    = "integrations/${aws_apigatewayv2_integration.guestbook_lambda.id}"
}

resource "aws_apigatewayv2_route" "guestbook_list" {
  api_id    = aws_apigatewayv2_api.guestbook.id
  route_key = "GET /guestbook"
  target    = "integrations/${aws_apigatewayv2_integration.guestbook_lambda.id}"
}

resource "aws_apigatewayv2_route" "guestbook_sign" {
  api_id    = aws_apigatewayv2_api.guestbook.id
  route_key = "POST /guestbook"
  target    = "integrations/${aws_apigatewayv2_integration.guestbook_lambda.id}"
}

resource "aws_apigatewayv2_route" "guestbook_delete" {
  api_id    = aws_apigatewayv2_api.guestbook.id
  route_key = "DELETE /guestbook/{entryId}"
  target    = "integrations/${aws_apigatewayv2_integration.guestbook_lambda.id}"
}

# ──────────────────────────────────────────────
# Stage (auto-deploy)
# ──────────────────────────────────────────────
resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.guestbook.id
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
      Name        = "${var.domain_name}-guestbook-api-stage"
      Environment = var.environment
    }
  )
}

resource "aws_cloudwatch_log_group" "api_gateway" {
  name              = "/aws/apigateway/${replace(var.domain_name, ".", "-")}-guestbook-api"
  retention_in_days = 14

  tags = merge(
    var.tags,
    {
      Name        = "${var.domain_name}-api-gateway-logs"
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
  function_name = aws_lambda_function.guestbook_api.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.guestbook.execution_arn}/*/*"
}

# ──────────────────────────────────────────────
# Custom Domain for API Gateway
# ──────────────────────────────────────────────
resource "aws_apigatewayv2_domain_name" "api" {
  domain_name = "api.${var.domain_name}"

  domain_name_configuration {
    certificate_arn = aws_acm_certificate.api_cert.arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }

  depends_on = [aws_acm_certificate_validation.api_cert_validation]

  tags = merge(
    var.tags,
    {
      Name        = "${var.domain_name}-api-domain"
      Environment = var.environment
    }
  )
}

resource "aws_apigatewayv2_api_mapping" "api" {
  api_id      = aws_apigatewayv2_api.guestbook.id
  domain_name = aws_apigatewayv2_domain_name.api.id
  stage       = aws_apigatewayv2_stage.default.id
}
