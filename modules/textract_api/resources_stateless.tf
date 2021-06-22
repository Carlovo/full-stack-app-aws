resource "aws_s3_bucket" "image_uploads" {
  force_destroy = true

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["POST"]
    allowed_origins = ["*"]
  }

  lifecycle_rule {
    id      = "delete-all-1-day"
    enabled = true

    abort_incomplete_multipart_upload_days = 1

    noncurrent_version_expiration {
      days = 1
    }

    expiration {
      days = 1
    }
  }
}
