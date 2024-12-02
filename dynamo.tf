resource "aws_dynamodb_table" "mojo_users_table" {
  name           = "${var.app_name}-users-${var.environment}"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "email"  # Changed to email as primary key since that's what we use
  stream_enabled = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  # Primary key
  attribute {
    name = "email"
    type = "S"
  }

  # Fields we don't need to define as attributes:
  # - password (string)
  # - name (string)
  # - isAdmin (boolean)
  # - created_at (string)
  # Note: In DynamoDB, we only define attributes that are used as keys

  tags = {
    Environment = var.environment
    Application = var.app_name
  }
}