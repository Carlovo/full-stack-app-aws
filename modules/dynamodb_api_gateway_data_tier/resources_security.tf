module "api_gateway_crud_dynamodb_items_role" {
  source = "../service_role"

  role_name    = "crud-${aws_dynamodb_table.this.name}"
  service_name = "apigateway"

  permission_statements = [{
    actions = [
      "dynamodb:Scan",
      "dynamodb:BatchWriteItem",
      "dynamodb:DeleteItem",
      "dynamodb:UpdateItem"
    ]
    resources = [aws_dynamodb_table.this.arn]
  }]
}
