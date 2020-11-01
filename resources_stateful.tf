resource "aws_dynamodb_table" "minimal_backend_table" {
  name           = aws_s3_bucket.minimal_frontend_bucket.id
  billing_mode   = "PROVISIONED"
  read_capacity  = 5
  write_capacity = 5
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }
}
