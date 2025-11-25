resource "aws_s3_bucket" "media_bucket" {
  bucket = var.bucket_media
}

resource "aws_s3_bucket" "raw_bucket" {
  bucket = var.bucket_raw
}

resource "aws_s3_bucket" "processed_bucket" {
  bucket = var.bucket_processed
}
