# Fetch GitHub OIDC thumbprint
data "tls_certificate" "github" {
  url = "https://token.actions.githubusercontent.com"
}

# Get current AWS account id to scope ARNs
data "aws_caller_identity" "current" {}

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
        # Restrict to instances in this account and region
        Resource = [
          "arn:aws:ec2:${var.region}:${data.aws_caller_identity.current.account_id}:instance/*"
        ]
        Condition = {
          StringEquals = {
            "ec2:osuser": "Administrator"
          }
        }
      }
      ,
      {
        # Some EC2 Describe* actions do not support resource-level permissions.
        # Use Resource = "*" for describe/read-only actions but constrain by region
        # to reduce blast-radius.
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceStatus",
          "ec2:DescribeTags",
          "ec2:DescribeAddresses",
          "ec2:DescribeNetworkInterfaces"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:RequestedRegion": "${var.region}"
          }
        }
      },
      {
        # Allow sending and checking SSM Run Command invocations. This lets the workflow
        # run PowerShell scripts (eg. restart IIS/app-pool) using the AWS-RunPowerShellScript
        # document. Instances must have the SSM agent and an instance profile like
        # AmazonSSMManagedInstanceCore attached.
        Effect = "Allow"
        Action = [
          "ssm:SendCommand",
          "ssm:GetCommandInvocation",
          "ssm:ListCommands",
          "ssm:ListCommandInvocations",
          "ssm:DescribeInstanceInformation",
          "ssm:StartSession",
          "ssm:DescribeSessions",
          "ssm:ListSessions"
        ]
        Resource = "*"
      }
    ]
  })
}

# Output the role ARN for use in GitHub Actions
output "github_actions_role_arn" {
  value = aws_iam_role.github_actions.arn
  description = "ARN of the GitHub Actions OIDC role"
}