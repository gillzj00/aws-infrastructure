output "s3_bucket" {
  description = "S3 bucket created for Terraform state"
  value       = aws_s3_bucket.tfstate.id
}

output "dynamodb_table" {
  description = "DynamoDB table created for Terraform state locking"
  value       = aws_dynamodb_table.tf_locks.name
}
