output "api_url" {
  description = "Custom domain URL for the golf league API"
  value       = "https://api.golf.${var.hosted_zone_name}"
}

output "api_gateway_url" {
  description = "API Gateway HTTP API URL (default endpoint)"
  value       = aws_apigatewayv2_api.api.api_endpoint
}

output "github_actions_role_arn" {
  description = "ARN of the GitHub Actions OIDC role for golf-sim-league repo"
  value       = aws_iam_role.github_actions.arn
}

output "deploy_bucket_name" {
  description = "S3 bucket for Lambda deployment artifacts"
  value       = aws_s3_bucket.deploy.id
}

output "site_bucket_name" {
  description = "S3 bucket for SPA static files"
  value       = aws_s3_bucket.site.id
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID for cache invalidation"
  value       = aws_cloudfront_distribution.site.id
}

output "lambda_function_name" {
  description = "Lambda function name for API deployment"
  value       = aws_lambda_function.api.function_name
}

output "leagues_table_name" {
  description = "DynamoDB table name for leagues"
  value       = aws_dynamodb_table.leagues.name
}

output "players_table_name" {
  description = "DynamoDB table name for players"
  value       = aws_dynamodb_table.players.name
}

output "rounds_table_name" {
  description = "DynamoDB table name for rounds"
  value       = aws_dynamodb_table.rounds.name
}

output "scores_table_name" {
  description = "DynamoDB table name for scores"
  value       = aws_dynamodb_table.scores.name
}
