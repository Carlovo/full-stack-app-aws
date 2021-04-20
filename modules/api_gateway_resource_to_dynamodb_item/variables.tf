variable "rest_api_id" {
  type        = string
  description = "ID of the API to which to add this integration."
}

variable "parent_id" {
  type        = string
  description = "ID of the resource (path) to which this integration will be appended."
}

variable "execution_role_arn" {
  type        = string
  description = "The role with which to execute the API."
}

variable "table_name" {
  type        = string
  description = "Identifier name of the DynamoDB table."
}
