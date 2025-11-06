resource "aws_security_group" "alb_sg" {
  name        = "alb-https-sg"
  description = "Allow HTTPS to ALB"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.domain_name}-alb-sg"
      Environment = var.environment
    }
  )
}

resource "aws_security_group" "instance_sg" {
  name        = "web-instance-sg"
  description = "Allow HTTP from ALB only"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port                = 80
    to_port                  = 80
    protocol                 = "tcp"
    security_groups          = [aws_security_group.alb_sg.id]
    description              = "Allow HTTP from ALB"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.domain_name}-instance-sg"
      Environment = var.environment
    }
  )
}