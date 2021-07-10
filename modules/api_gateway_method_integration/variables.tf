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

variable "integration_uri" {
  type        = string
  description = "The API Gateway uri to perform the action against."
}

variable "request_transformation" {
  type        = string
  description = "The template to translate the json from the request to DynamoDB terms."
}

variable "response_transformation" {
  type        = string
  default     = null
  description = "The template to translate the json from the response from DynamoDB terms."
}

variable "extra_response_parameters" {
  type        = map(string)
  default     = {}
  description = "The response parameters that should be present next to 'Access-Control-Allow-Origin'."
}

variable "enforce_api_key" {
  type        = bool
  default     = false
  description = "Enforce the usage of a key in the header of all requests to this API."
}
