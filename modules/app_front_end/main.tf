resource "aws_s3_bucket_object" "app_html" {
  bucket       = var.frontend_bucket
  key          = "${var.app_page_name}.html"
  content_type = "text/html"
  acl          = var.insecure ? "public-read" : "private"

  content = templatefile(
    "./resources_front_end/app.html",
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
    "./resources_front_end/app.js",
    {
      api_url = var.api_invoke_url
    }
  )
}
