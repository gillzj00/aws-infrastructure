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

  backend "s3" {
    bucket         = "terraform-state-dev-174230265051"
    key            = "dev/aws-infrastructure/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "terraform-state-locks"
    encrypt        = true
  }
}