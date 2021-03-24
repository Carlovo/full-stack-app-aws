resource "aws_dynamodb_table" "main" {
  for_each = var.tables

  name         = "${local.unique_name_prefix}${each.key}"
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
