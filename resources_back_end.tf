module "app_back_end" {
  source = "./modules/app_back_end"

  resource_name = aws_s3_bucket.front_end.id
}
