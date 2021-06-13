variable "role_name" {
  type        = string
  description = "The name of the IAM role."
}

variable "service_name" {
  type        = string
  description = "The name of the serive to trust the IAM role with."
}

variable "permission_statements" {
  type = list(object({
    actions   = list(string)
    resources = list(string)
  }))
  description = "The permissions of the service role."
}
