resource "aws_s3_bucket" "frontend_bucket" {
  # bucket policy is managed in a separate resource to avoid cyclic dependancies
  acl = var.insecure ? "public-read" : "private"
}

locals {
  app_html_links = [for app_name in var.apps : "<a href=\"${app_name}.html\">${app_name}</a>"]
}

resource "aws_s3_bucket_object" "index" {
  bucket       = aws_s3_bucket.frontend_bucket.id
  key          = "index.html"
  content_type = "text/html"
  acl          = var.insecure ? "public-read" : "private"

  content = templatefile(
    "./resources_front_end/index.html",
    {
      app_links = join("<br><br>\n", local.app_html_links)
    }
  )
}

module "app_front_ends" {
  for_each = var.apps

  source = "./modules/app_front_end"

  frontend_bucket = aws_s3_bucket.frontend_bucket.bucket
  app_page_name   = each.key
  api_invoke_url  = aws_api_gateway_deployment.minimal.invoke_url
  insecure        = var.insecure
}
