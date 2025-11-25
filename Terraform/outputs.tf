output "api_invoke_url" {
  value = module.api_gateway.invoke_url
}

output "sns_topic_arn" {
  value = module.sns.arn
}

output "raw_bucket" {
  value = module.storage.raw_bucket
}

output "processed_bucket" {
  value = module.storage.processed_bucket
}

output "cognito_user_pool_id" {
  value = module.cognito.user_pool_id
}

output "cognito_user_pool_client_id" {
  value = module.cognito.client_id
}
