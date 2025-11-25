module "storage" {
  source           = "./modules/storage"
  bucket_media     = var.bucket_media
  bucket_raw       = var.bucket_raw
  bucket_processed = var.bucket_processed
}

module "sns" {
  source = "./modules/sns_topic"
  name   = var.sns_topic_name
}

module "cognito" {
  source          = "./modules/cognito"
  user_pool_name  = "clickstream-user-pool"
  client_name     = "clickstream-client"
}

module "iam_lambda" {
  source      = "./modules/iam_lambda"
  role_name   = "lambda-role"
  policy_name = "lambda-s3-logs"
}

module "lambda_ingest" {
  source      = "./modules/lambda_function"
  function_name = "ClickstreamIngest"
  role_arn      = module.iam_lambda.role_arn
  handler       = var.lambda_handler
  runtime       = var.lambda_runtime
  filename      = var.lambda_ingest_zip

  environment_variables = {
    RAW_BUCKET = module.storage.raw_bucket
    TOPIC_ARN  = module.sns.arn
  }
}

module "lambda_etl" {
  source      = "./modules/lambda_function"
  function_name = "ClickstreamETL"
  role_arn      = module.iam_lambda.role_arn
  handler       = var.lambda_handler
  runtime       = var.lambda_runtime
  filename      = var.lambda_etl_zip

  environment_variables = {
    RAW_BUCKET       = module.storage.raw_bucket
    PROCESSED_BUCKET = module.storage.processed_bucket
  }
}

module "api_gateway" {
  source               = "./modules/api_gateway_proxy"
  api_name             = "click-api"
  path_part            = "click"
  http_method          = "POST"
  lambda_invoke_arn    = module.lambda_ingest.invoke_arn
  lambda_function_name = module.lambda_ingest.function_name
  stage_name           = local.api_stage
}

module "eventbridge" {
  source               = "./modules/eventbridge_rule"
  name                 = "etl-hourly"
  schedule_expression  = "cron(0 * * * ? *)"
  lambda_arn           = module.lambda_etl.arn
  lambda_name          = module.lambda_etl.function_name
  target_id            = "etl-lambda"
}
