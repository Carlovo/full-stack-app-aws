data "aws_region" "current" {}

variable "rest_api_id" {
  type        = string
  description = "ID of the API to which to add this integration."
}

variable "api_gateway_resource_id" {
  type        = string
  description = "ID of the resource (path) to which to add this integration."
}

variable "http_method" {
  type        = string
  description = "The http method to create in this path."
}

variable "execution_role_arn" {
  type        = string
  description = "The role with which to execute the API."
}

variable "dynamodb_action" {
  type        = string
  description = "The action to perform on the DynamoDB resource."
}

variable "transformation_template" {
  type        = string
  description = "The template to translate the json from the request to DynamoDB terms."
}
