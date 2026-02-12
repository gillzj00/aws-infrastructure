variable "region" {
  description = "AWS region to create the bootstrap resources in"
  type        = string
  default     = "us-west-2"
}

variable "environment" {
  description = "Environment tag used on created resources"
  type        = string
  default     = "dev"
}

variable "bucket_name" {
  description = "Name of the S3 bucket to create for storing Terraform state. Must be globally unique."
  type        = string
  default     = ""
}

variable "dynamodb_table_name" {
  description = "Name of the DynamoDB table used for Terraform state locking"
  type        = string
  default     = "terraform-state-locks"
}
