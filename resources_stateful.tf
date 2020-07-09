resource "aws_dynamodb_table" "minimal_backend_table" {
  name           = "minimal-backend-table"
  billing_mode   = "PROVISIONED"
  read_capacity  = 5
  write_capacity = 5
  hash_key       = "id"

  attribute {
    name = "id"
    type = "N"
  }
}
