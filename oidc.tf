# Fetch GitHub OIDC thumbprint
data "tls_certificate" "github" {
  url = "https://token.actions.githubusercontent.com"
}

resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = ["sts.amazonaws.com"]

  tags = merge(
    var.tags,
    {
      Name = "github-actions"
    }
  )
}

resource "aws_iam_role" "github_actions" {
  name = "github-actions-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Condition = {
          StringLike = {
            "token.actions.githubusercontent.com:sub": "repo:gillzj00/aws-infrastructure:*"
          }
        }
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name = "github-actions-role"
    }
  )
}

# Policy to allow S3 access and EC2 instance connect
resource "aws_iam_role_policy" "github_actions_policy" {
  name = "github-actions-policy"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.domain_name}/*",
          "arn:aws:s3:::${var.domain_name}"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "ec2-instance-connect:SendSSHPublicKey"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "ec2:osuser": "Administrator"
          }
        }
      }
    ]
  })
}

# Output the role ARN for use in GitHub Actions
output "github_actions_role_arn" {
  value = aws_iam_role.github_actions.arn
  description = "ARN of the GitHub Actions OIDC role"
}