resource "aws_s3_bucket" "this" {
  bucket = "${var.app_id}-front-end"

  # bucket policy is managed in a separate resource to avoid cyclic dependancies
  acl = var.insecure ? "public-read" : "private"
}

resource "aws_s3_bucket_object" "index" {
  bucket       = aws_s3_bucket.this.id
  key          = "index.html"
  content_type = "text/html"
  acl          = var.insecure ? "public-read" : "private"

  content = templatefile(
    "${path.module}/content/templates/index.html",
    {
      table_query_links = join("</td></tr><tr><td>", [for table_name in var.tables : "<a href=\"?table=${table_name}\">${table_name}</a>"])
      textract_api_html = var.textract_api_url == "" ? "<!-- not available -->" : file("${path.module}/content/templates/textract_api.html")
    }
  )
}

resource "aws_s3_bucket_object" "script" {
  bucket       = aws_s3_bucket.this.id
  key          = "index.js"
  content_type = "text/javascript"
  acl          = var.insecure ? "public-read" : "private"

  content = templatefile(
    "${path.module}/content/templates/index.js",
    {
      crud_api_url            = var.crud_api_url
      crud_api_key            = var.crud_api_key
      textract_api_url        = var.textract_api_url == "" ? "not available" : var.textract_api_url
      image_upload_bucket_url = var.textract_api_url == "" ? "not available" : var.image_upload_bucket_url
    }
  )
}

resource "aws_s3_bucket_object" "page_404" {
  bucket       = aws_s3_bucket.this.id
  key          = "404.html"
  content_type = "text/html"
  acl          = var.insecure ? "public-read" : "private"

  content = file("${path.module}/content/404.html")
}
