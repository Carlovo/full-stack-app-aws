variable "app_id" {
  type        = string
  description = "Consistent id for resources that need a unique name."
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

variable "enforce_api_key" {
  type        = bool
  default     = false
  description = "Enforce the usage of a key in the header of all requests to this API."
}
