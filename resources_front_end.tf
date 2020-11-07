resource "aws_s3_bucket" "minimal_frontend_bucket" {
  # bucket policy is managed in a separate resource to avoid cyclic dependancies
  acl = var.insecure ? "public-read" : "private"
}

resource "aws_s3_bucket_object" "index" {
  bucket       = aws_s3_bucket.minimal_frontend_bucket.id
  key          = "index.html"
  content_type = "text/html"
  acl          = var.insecure ? "public-read" : "private"

  content = file("./resources_front_end/index.html")
}

resource "aws_s3_bucket_object" "app_html" {
  bucket       = aws_s3_bucket.minimal_frontend_bucket.id
  key          = "app.html"
  content_type = "text/html"
  acl          = var.insecure ? "public-read" : "private"

  content = file("./resources_front_end/app.html")
}

resource "aws_s3_bucket_object" "app_script" {
  bucket = aws_s3_bucket.minimal_frontend_bucket.id
  key    = "app.js"
  acl    = var.insecure ? "public-read" : "private"

  content = templatefile(
    "./resources_front_end/app.js",
    {
      api_url = aws_api_gateway_deployment.minimal.invoke_url
    }
  )
}
