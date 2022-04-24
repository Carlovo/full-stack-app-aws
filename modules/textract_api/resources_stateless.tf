resource "aws_s3_bucket" "image_uploads" {
  bucket        = "${var.app_id}-textract-image-uploads"
  force_destroy = true
}

resource "aws_s3_bucket_cors_configuration" "image_uploads" {
  bucket = aws_s3_bucket.image_uploads.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["POST"]
    allowed_origins = ["*"]
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "image_uploads" {
  bucket = aws_s3_bucket.image_uploads.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "image_uploads" {
  bucket = aws_s3_bucket.image_uploads.id

  rule {
    id     = "delete-all-1-day"
    status = "Enabled"

    abort_incomplete_multipart_upload {
      days_after_initiation = 1
    }

    noncurrent_version_expiration {
      noncurrent_days = 1
    }

    expiration {
      days = 1
    }
  }
}
