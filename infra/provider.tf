provider "aws" {
  region = var.region
}

# CloudFront requires ACM certificates in us-east-1
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

terraform {
  required_version = "~> 1.9"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }

  # Backend values are placeholders — overridden by -backend-config flags in CI
  # and during local `terraform init`. See .github/workflows/main.yml.
  backend "s3" {
    bucket         = "PLACEHOLDER"
    key            = "PLACEHOLDER"
    region         = "us-west-2"
    dynamodb_table = "terraform-state-locks"
    encrypt        = true
  }
}