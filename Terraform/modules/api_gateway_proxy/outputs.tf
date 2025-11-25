output "rest_api_id" {
  value = aws_api_gateway_rest_api.this.id
}

output "invoke_url" {
  value = "http://localhost:4566/restapis/${aws_api_gateway_rest_api.this.id}/${aws_api_gateway_stage.stage.stage_name}/_user_request_/${var.path_part}"
}
