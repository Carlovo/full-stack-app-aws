variable "frontend_bucket" {
  type        = string
  description = "Name of the bucket in which the app front end pages must be stored."
}

variable "app_page_name" {
  type        = string
  description = "The page name this app will have."
}

variable "api_invoke_url" {
  type        = string
  description = "The URL to reach the back end API of this app."
}

variable "insecure" {
  type        = bool
  description = "Prevent exclusive CloudFront access to content S3 bucket. Useful for faster development."
}
