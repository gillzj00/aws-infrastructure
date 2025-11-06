# Data sources
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Use first available public subnet(s) for ALB
locals {
  alb_subnets = slice(data.aws_subnets.default.ids, 0, 2)
}

# Find a recent Windows Server AMI
data "aws_ami" "windows" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["Windows_Server-2019-English-Full-Base-*", "Windows_Server-2022-English-Full-Base-*"]
  }
}

# Route53 zone
resource "aws_route53_zone" "primary" {
  name    = var.hosted_zone_name
  comment = "Route53 hosted zone for website managed by Terraform"

  tags = merge(
    var.tags,
    {
      Name        = var.hosted_zone_name
      Environment = var.environment
    }
  )
}



# EC2 Instance
resource "aws_instance" "web" {
  ami                         = data.aws_ami.windows.id
  instance_type               = var.instance_type
  subnet_id                   = data.aws_subnets.default.ids[0]
  vpc_security_group_ids      = [aws_security_group.instance_sg.id]
  associate_public_ip_address = true

  user_data = <<-POWERSHELL
    <powershell>
    Install-WindowsFeature -Name Web-Server -IncludeManagementTools
    $content = "<html><body><h1>${var.domain_name}</h1><p>Hostname: $env:COMPUTERNAME</p></body></html>"
    Set-Content -Path C:\\inetpub\\wwwroot\\index.html -Value $content -Encoding UTF8
    </powershell>
  POWERSHELL

  tags = merge(
    var.tags,
    {
      Name        = "${var.domain_name}-web"
      Environment = var.environment
    }
  )
}

# DNS record for the website
resource "aws_route53_record" "site_alias" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_lb.app.dns_name
    zone_id                = aws_lb.app.zone_id
    evaluate_target_health = true
  }
}
