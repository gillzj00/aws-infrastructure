# ──────────────────────────────────────────────
# SSM SecureString — canonical store for the email
# ──────────────────────────────────────────────
resource "aws_ssm_parameter" "notification_email" {
  name        = "/${var.environment}/budget/notification-email"
  description = "Email address for budget alert notifications"
  type        = "SecureString"
  value       = var.notification_email

  tags = merge(
    var.tags,
    {
      Name        = "${var.domain_name}-notification-email"
      Environment = var.environment
    }
  )
}

# ──────────────────────────────────────────────
# SNS topic + policy for budget alerts
# ──────────────────────────────────────────────
resource "aws_sns_topic" "budget_alerts" {
  name = "${var.domain_name}-budget-alerts"

  tags = merge(
    var.tags,
    {
      Name        = "${var.domain_name}-budget-alerts"
      Environment = var.environment
    }
  )
}

resource "aws_sns_topic_policy" "budget_alerts" {
  arn = aws_sns_topic.budget_alerts.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowBudgetPublish"
        Effect = "Allow"
        Principal = {
          Service = "budgets.amazonaws.com"
        }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.budget_alerts.arn
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
}

resource "aws_sns_topic_subscription" "budget_email" {
  topic_arn = aws_sns_topic.budget_alerts.arn
  protocol  = "email"
  endpoint  = var.notification_email
}

# ──────────────────────────────────────────────
# Monthly cost budget — $50 with 50/80/100% alerts
# ──────────────────────────────────────────────
resource "aws_budgets_budget" "monthly" {
  name         = "${var.domain_name}-monthly-budget"
  budget_type  = "COST"
  limit_amount = "50"
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  notification {
    comparison_operator       = "GREATER_THAN"
    threshold                 = 50
    threshold_type            = "PERCENTAGE"
    notification_type         = "ACTUAL"
    subscriber_sns_topic_arns = [aws_sns_topic.budget_alerts.arn]
  }

  notification {
    comparison_operator       = "GREATER_THAN"
    threshold                 = 80
    threshold_type            = "PERCENTAGE"
    notification_type         = "ACTUAL"
    subscriber_sns_topic_arns = [aws_sns_topic.budget_alerts.arn]
  }

  notification {
    comparison_operator       = "GREATER_THAN"
    threshold                 = 100
    threshold_type            = "PERCENTAGE"
    notification_type         = "ACTUAL"
    subscriber_sns_topic_arns = [aws_sns_topic.budget_alerts.arn]
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.domain_name}-monthly-budget"
      Environment = var.environment
    }
  )
}
