resource "aws_s3_bucket" "image_uploads" {
  bucket = "${var.app_id}-textract-image-uploads"

  force_destroy = true

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["POST"]
    allowed_origins = ["*"]
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm     = "AES256"
      }
    }
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
