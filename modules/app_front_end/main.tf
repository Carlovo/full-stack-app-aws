resource "aws_s3_bucket_object" "app_html" {
  bucket       = var.frontend_bucket
  key          = "${var.app_page_name}.html"
  content_type = "text/html"
  acl          = var.insecure ? "public-read" : "private"

  content = templatefile(
    "${path.module}/app.html",
    {
      app_name = var.app_page_name
    }
  )
}

resource "aws_s3_bucket_object" "app_script" {
  bucket = var.frontend_bucket
  key    = "${var.app_page_name}.js"
  acl    = var.insecure ? "public-read" : "private"

  content = templatefile(
    "${path.module}/app.js",
    {
      api_url = var.api_invoke_url
    }
  )
}
