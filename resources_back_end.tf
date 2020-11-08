module "app_back_end" {
  for_each = var.apps

  source = "./modules/app_back_end"

  resource_name = "tf-${split("-", aws_s3_bucket.front_end.id)[1]}-${each.key}"
}
