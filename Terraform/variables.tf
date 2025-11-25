variable "region" {
  description = "AWS region for LocalStack emulation."
  type        = string
  default     = "ap-southeast-1"
}

variable "localstack_endpoint" {
  description = "Base edge endpoint for LocalStack."
  type        = string
  default     = "http://localhost:4566"
}

variable "bucket_media" {
  description = "Media/assets bucket name."
  type        = string
  default     = "local-media-assets"
}

variable "bucket_raw" {
  description = "Raw clickstream bucket name."
  type        = string
  default     = "local-clickstream-raw"
}

variable "bucket_processed" {
  description = "Processed clickstream bucket name."
  type        = string
  default     = "local-clickstream-processed"
}

variable "sns_topic_name" {
  description = "Alerts topic name."
  type        = string
  default     = "clickstream-local-alerts"
}

variable "lambda_runtime" {
  description = "Runtime for Lambda functions."
  type        = string
  default     = "python3.10"
}

variable "lambda_handler" {
  description = "Default handler for packaged lambdas."
  type        = string
  default     = "lambda_function.lambda_handler"
}

variable "lambda_ingest_zip" {
  description = "Path to ingest lambda zip."
  type        = string
  default     = "output/lambda_ingest.zip"
}

variable "lambda_etl_zip" {
  description = "Path to ETL lambda zip."
  type        = string
  default     = "output/lambda_etl.zip"
}

locals {
  api_stage = "prod"
}
