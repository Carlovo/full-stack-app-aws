resource "aws_dynamodb_table" "this" {
  name         = "${var.app_id}-${var.table}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }
}
