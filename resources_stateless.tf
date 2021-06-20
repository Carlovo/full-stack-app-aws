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
    "./terraform_templates/front_end/index.html",
    {
      table_query_links = join("</td></tr><tr><td>", local.table_query_links)
      textract_api_html = var.textract_api ? file("./terraform_templates/front_end/textract_api.html") : "<!-- not available -->"
    }
  )
}

resource "aws_s3_bucket_object" "script" {
  bucket       = aws_s3_bucket.front_end.id
  key          = "index.js"
  content_type = "text/javascript"
  acl          = var.insecure ? "public-read" : "private"

  content = templatefile(
    "./terraform_templates/front_end/index.js",
    {
      crud_api_url                     = var.alternate_domain_name == "" ? "${aws_api_gateway_stage.crud.invoke_url}/" : "https://${aws_api_gateway_base_path_mapping.alias[0].domain_name}/"
      textract_api_url                 = var.textract_api ? "https://${module.textract_api[0].invoke_url}/" : "not available"
      image_upload_bucket_regional_url = var.textract_api ? module.textract_api[0].bucket_regional_domain_name : "not available"
    }
  )
}

resource "aws_s3_bucket_object" "page_404" {
  bucket       = aws_s3_bucket.front_end.id
  key          = "404.html"
  content_type = "text/html"
  acl          = var.insecure ? "public-read" : "private"

  content = file("./terraform_templates/front_end/404.html")
}
