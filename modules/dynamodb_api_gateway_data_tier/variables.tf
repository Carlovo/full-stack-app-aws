variable "unique_name_prefix" {
  type        = string
  description = "The string used to make the name of the DynamoDB table and service roles unique."
}

variable "table" {
  type        = string
  description = "API Gateway resource: name of the path to be appended to the API URL."
}

variable "api_gateway_rest_api_id" {
  type        = string
  description = "ID of the API to which to add this integration."
}

variable "parent_id" {
  type        = string
  description = "ID of the resource (path) to which this integration will be appended."
}
