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
      crud_api_url       = var.alternate_domain_name == "" ? aws_api_gateway_deployment.crud.invoke_url : "https://${aws_api_gateway_base_path_mapping.alias[0].domain_name}/"
      s3_presign_api_url = var.alternate_domain_name == "" ? aws_apigatewayv2_stage.s3_presign.invoke_url : "https://${aws_apigatewayv2_domain_name.alias[0].domain_name}/"
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
