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

variable "unique_name_prefix" {
  type        = string
  description = "Prefix of the DynamoDB table names."
}

variable "table" {
  type        = string
  description = "Identifier appendix of the DynamoDB table names."
}
