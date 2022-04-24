resource "aws_s3_bucket" "this" {
  bucket = "${var.app_id}-front-end"
  # bucket policy is managed in a separate resource to avoid cyclic dependencies
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_acl" "this" {
  bucket = aws_s3_bucket.this.id
  acl    = var.insecure ? "public-read" : "private"
}

locals {
  index_content = templatefile(
    "${path.module}/content/templates/index.html",
    {
      table_query_links = join("</td></tr><tr><td>", [for table_name in var.tables : "<a href=\"?table=${table_name}\">${table_name}</a>"])
      textract_api_html = var.textract_api_url == "" ? "<!-- not available -->" : file("${path.module}/content/templates/textract_api.html")
    }
  )
  api_client_library_content = templatefile(
    "${path.module}/content/templates/api_client_library.js",
    {
      crud_api_tables         = jsonencode(var.tables)
      crud_api_url            = var.crud_api_url
      crud_api_key            = var.crud_api_key
      textract_api_url        = var.textract_api_url == "" ? "not available" : var.textract_api_url
      image_upload_bucket_url = var.textract_api_url == "" ? "not available" : var.image_upload_bucket_url
    }
  )
  script_content  = file("${path.module}/content/main.js")
  page404_content = file("${path.module}/content/404.html")
}


resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.this.id
  key          = "index.html"
  content_type = "text/html"
  acl          = var.insecure ? "public-read" : "private"
  content      = local.index_content
  etag         = md5(local.index_content)
}

resource "aws_s3_object" "api_client_library" {
  bucket       = aws_s3_bucket.this.id
  key          = "api_client_library.js"
  content_type = "text/javascript"
  acl          = var.insecure ? "public-read" : "private"
  content      = local.api_client_library_content
  etag         = md5(local.api_client_library_content)
}

resource "aws_s3_object" "script" {
  bucket       = aws_s3_bucket.this.id
  key          = "main.js"
  content_type = "text/javascript"
  acl          = var.insecure ? "public-read" : "private"
  content      = local.script_content
  etag         = md5(local.script_content)
}

resource "aws_s3_object" "page_404" {
  bucket       = aws_s3_bucket.this.id
  key          = "404.html"
  content_type = "text/html"
  acl          = var.insecure ? "public-read" : "private"
  content      = local.page404_content
  etag         = md5(local.page404_content)
}
