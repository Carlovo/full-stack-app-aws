variable "bucket_name" {
  type        = string
  description = "Name of the S3 bucket to put front-end content in."
}

variable "tables" {
  type        = set(string)
  description = "List of unique names (set of strings) for which the front end will show query options."
}

variable "crud_api_url" {
  type        = string
  description = "URL of the CRUD API."
}

variable "textract_api_url" {
  type        = string
  default     = ""
  description = "URL of Textract API, may be omitted if Textract API is not deployed."
}

variable "image_upload_bucket_url" {
  type        = string
  default     = ""
  description = "Regional URL of the bucket for image uploads, may be omitted if Textract API not deployed."
}

variable "crud_api_key" {
  type        = string
  default     = ""
  description = "The API key needed to access the CRUD API."
}

variable "app_landing_page_name" {
  type        = string
  default     = "index.html"
  description = "The URI resource name of app front end page."
}
