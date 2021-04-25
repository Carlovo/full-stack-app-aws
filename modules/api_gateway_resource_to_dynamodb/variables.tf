data "aws_region" "current" {}

variable "rest_api_id" {
  type        = string
  description = "ID of the API to which to add this integration."
}

variable "parent_id" {
  type        = string
  description = "ID of the resource (path) to which this integration will be appended."
}

variable "path_part" {
  type        = string
  description = "API Gateway resource: name of the path to be appended to the API URL."
}

variable "execution_role_arn" {
  type        = string
  description = "The role with which to execute the API."
}

variable "integrations" {
  type        = map(map(string))
  description = "Parameters to generate integrations."
}
