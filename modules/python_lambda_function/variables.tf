variable "function_name" {
  type        = string
  description = "The name of the Lambda function."
}

variable "extra_permission_statements" {
  type = list(object({
    actions   = list(string)
    resources = list(string)
  }))
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
