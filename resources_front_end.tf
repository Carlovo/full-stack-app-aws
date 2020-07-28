resource "aws_s3_bucket" "minimal_frontend_bucket" {
  # bucket policy is managed in a separate resource to avoid cyclic dependancies
}

resource "aws_s3_bucket_object" "minimal_index" {
  bucket       = aws_s3_bucket.minimal_frontend_bucket.id
  key          = "index.html"
  source       = "./resources_front_end/index.html"
  content_type = "text/html"
}

resource "aws_s3_bucket_object" "minimal_script" {
  bucket = aws_s3_bucket.minimal_frontend_bucket.id
  key    = "index.js"

  content = templatefile(
    "./resources_front_end/index.js",
    {
      api_url = aws_api_gateway_deployment.minimal.invoke_url
    }
  )
}
