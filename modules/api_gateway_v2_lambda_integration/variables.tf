variable "function_name" {
  type        = string
  description = "The name of the Lambda function."
}

variable "extra_permission_statements" {
  type = list(object({
    actions   = list(string)
    resources = list(string)
  }))
  default     = []
  description = "The permissions the Lambda function will get next to logging."
}

variable "source_code" {
  type        = string
  description = "The source code to load into the Lambda function."
}

variable "timeout" {
  type        = number
  default     = 3
  description = "The amount seconds the Lambda function will run before it times out."
}

variable "api_id" {
  type        = string
  description = "The id of the API Gateway V2 api to add this Lambda function integration to."
}

variable "http_method" {
  type        = string
  description = "The http method on which this api will be available."
}

variable "api_execution_arn" {
  type        = string
  description = "The execution arn of the API Gateway V2 api to add this Lambda function integration to."
}

variable "api_stage_name" {
  type        = string
  description = "The api stage on which this api will be available."
}
