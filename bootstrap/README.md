Bootstrap Terraform module

This folder contains a small Terraform configuration to create:

- an S3 bucket to hold Terraform state
- a DynamoDB table used by Terraform to obtain locks during apply

This module is intentionally separate from your main Terraform code so you can create the backend resources BEFORE configuring the S3 backend in your main workspace.

Usage

1. Pick a globally-unique S3 bucket name and optionally a different DynamoDB table name.

2. Export an AWS profile or credentials that have permissions to create S3 and DynamoDB resources.

   ```bash
   export AWS_PROFILE=myprofile
   # or
   export AWS_ACCESS_KEY_ID=AKIA...
   export AWS_SECRET_ACCESS_KEY=...
   ```

3. Initialize and apply the bootstrap module, passing the bucket name:

   ```bash
   cd bootstrap
   terraform init
   terraform apply -var="bucket_name=my-unique-terraform-state-bucket" -auto-approve
   ```

4. After creation, add the following backend block to your main Terraform repo (update bucket, key, region and table):

   ```hcl
   terraform {
     backend "s3" {
       bucket         = "my-unique-terraform-state-bucket"
       key            = "path/to/terraform.tfstate"
       region         = "us-east-1"
       dynamodb_table = "terraform-state-locks"
       encrypt        = true
     }
   }
   ```

Notes

- The DynamoDB table created uses a string hash key named `LockID` which Terraform expects for state locking.
- The S3 bucket is created with versioning and server-side encryption enabled and a public access block.
- Do NOT commit credentials to git. Consider using `aws-vault` or AWS SSO for short-lived credentials.
