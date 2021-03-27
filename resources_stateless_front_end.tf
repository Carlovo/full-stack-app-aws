resource "aws_s3_bucket" "front_end" {
  # bucket policy is managed in a separate resource to avoid cyclic dependancies
  acl = var.insecure ? "public-read" : "private"
}

locals {
  table_query_links = [for table_name in var.tables : "<a href=\"?table=${table_name}\">${table_name}</a>"]
}

resource "aws_s3_bucket_object" "index" {
  bucket       = aws_s3_bucket.front_end.id
  key          = "index.html"
  content_type = "text/html"
  acl          = var.insecure ? "public-read" : "private"

  content = templatefile(
    "./index.html",
    {
      table_query_links = join("</td></tr><tr><td>", local.table_query_links)
    }
  )
}

resource "aws_s3_bucket_object" "script" {
  bucket       = aws_s3_bucket.front_end.id
  key          = "index.js"
  content_type = "text/javascript"
  acl          = var.insecure ? "public-read" : "private"

  content = templatefile(
    "./index.js",
    {
      api_url = aws_api_gateway_deployment.main.invoke_url
    }
  )
}

resource "aws_s3_bucket_object" "page_404" {
  bucket       = aws_s3_bucket.front_end.id
  key          = "404.html"
  content_type = "text/html"
  acl          = var.insecure ? "public-read" : "private"

  content = file("./404.html")
}
