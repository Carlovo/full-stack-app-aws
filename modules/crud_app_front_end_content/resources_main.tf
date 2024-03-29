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
  bucket       = var.bucket_name
  key          = var.app_landing_page_name
  content_type = "text/html"
  content      = local.index_content
  etag         = md5(local.index_content)
}

resource "aws_s3_object" "api_client_library" {
  bucket       = var.bucket_name
  key          = "api_client_library.js"
  content_type = "text/javascript"
  content      = local.api_client_library_content
  etag         = md5(local.api_client_library_content)
}

resource "aws_s3_object" "script" {
  bucket       = var.bucket_name
  key          = "main.js"
  content_type = "text/javascript"
  content      = local.script_content
  etag         = md5(local.script_content)
}

resource "aws_s3_object" "page_404" {
  bucket       = var.bucket_name
  key          = "404.html"
  content_type = "text/html"
  content      = local.page404_content
  etag         = md5(local.page404_content)
}
