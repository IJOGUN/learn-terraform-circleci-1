provider "aws" {
  region = var.region

  default_tags {
    tags = {
      hashicorp-learn = "circleci"
    }
  }
}

resource "random_uuid" "randomid" {}

resource "aws_s3_bucket" "app" {
  tags = {
    Name          = "App Bucket"
    public_bucket = true
  }

  bucket        = "${var.app}.${var.label}.${random_uuid.randomid.result}"
  force_destroy = true
}

resource "aws_s3_bucket_ownership_controls" "app" {
  bucket = aws_s3_bucket.app.id

  rule {
    object_ownership = "BucketOwnerEnforced" # Enforces ownership and disables ACLs
  }
}

resource "aws_s3_bucket_public_access_block" "app" {
  bucket = aws_s3_bucket.app.id

  block_public_acls       = true
  block_public_policy     = false
  ignore_public_acls      = true
  restrict_public_buckets = false
}

# REMOVE THIS BLOCK - ACLs are not supported with "BucketOwnerEnforced"
# resource "aws_s3_bucket_acl" "app" {
#   depends_on = [
#     aws_s3_bucket_ownership_controls.app,
#     aws_s3_bucket_public_access_block.app,
#   ]
#   bucket = aws_s3_bucket.app.id
#   acl    = "public-read"
# }

resource "aws_s3_bucket_policy" "public_read" {
  bucket = aws_s3_bucket.app.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "PublicReadGetObject",
        Effect    = "Allow",
        Principal = "*",
        Action    = "s3:GetObject",
        Resource  = "${aws_s3_bucket.app.arn}/*"
      }
    ]
  })
}

resource "aws_s3_bucket_website_configuration" "app" {
  bucket = aws_s3_bucket.app.bucket

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

resource "aws_s3_object" "app" {
  key          = "index.html"
  bucket       = aws_s3_bucket.app.id
  content      = file("./assets/index.html")
  content_type = "text/html"
  # REMOVED: acl = "public-read"
}
