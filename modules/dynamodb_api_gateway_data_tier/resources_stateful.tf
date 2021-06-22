resource "aws_dynamodb_table" "this" {
  name         = "${var.unique_name_prefix}${var.table}"
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
