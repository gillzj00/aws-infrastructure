# Instance role for EC2
resource "aws_iam_role" "ec2_instance_role" {
  name = "web-server-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })

  tags = var.tags
}

# Instance profile (required to attach role to EC2)
resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "web-server-profile"
  role = aws_iam_role.ec2_instance_role.name
}

# Allow SSM access
resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Allow S3 read access for deployments
resource "aws_iam_role_policy" "s3_read" {
  name = "s3-read-policy"
  role = aws_iam_role.ec2_instance_role.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          "${aws_s3_bucket.deploy.arn}/*",
          "${aws_s3_bucket.deploy.arn}"
        ]
      }
    ]
  })
}