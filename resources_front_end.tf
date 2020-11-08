resource "aws_s3_bucket" "front_end" {
  # bucket policy is managed in a separate resource to avoid cyclic dependancies
  acl = var.insecure ? "public-read" : "private"
}

locals {
  app_html_links = [for app_name in var.apps : "<a href=\"${app_name}.html\">${app_name}</a>"]
}

resource "aws_s3_bucket_object" "index" {
  bucket       = aws_s3_bucket.front_end.id
  key          = "index.html"
  content_type = "text/html"
  acl          = var.insecure ? "public-read" : "private"

  content = templatefile(
    "./index.html",
    {
      app_links = join("<br><br>\n", local.app_html_links)
    }
  )
}

module "app_front_ends" {
  for_each = var.apps

  source = "./modules/app_front_end"

  front_end_bucket = aws_s3_bucket.front_end.bucket
  app_page_name    = each.key
  api_invoke_url   = module.app_back_end[each.key].api_invoke_url
  insecure         = var.insecure
}
