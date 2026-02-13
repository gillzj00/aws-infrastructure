# DynamoDB table for guestbook entries
# PAY_PER_REQUEST = on-demand pricing ($0 at low traffic, no capacity planning)
resource "aws_dynamodb_table" "guestbook" {
  name         = "${replace(var.domain_name, ".", "-")}-guestbook"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "entryId"

  attribute {
    name = "entryId"
    type = "S"
  }

  # Non-key attributes (name, githubUsername, message, signedAt) don't need
  # to be declared — DynamoDB is schemaless for non-key attributes.

  tags = merge(
    var.tags,
    {
      Name        = "${var.domain_name}-guestbook"
      Environment = var.environment
    }
  )
}
