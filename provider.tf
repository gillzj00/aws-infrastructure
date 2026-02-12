provider "aws" {
  region  = "us-west-2"
}

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    tls = {
      source = "hashicorp/tls"
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