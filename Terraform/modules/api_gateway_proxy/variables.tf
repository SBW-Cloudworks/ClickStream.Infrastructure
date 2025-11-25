variable "api_name" {
  type        = string
  description = "API Gateway name."
}

variable "path_part" {
  type        = string
  description = "Resource path part."
}

variable "http_method" {
  type        = string
  description = "HTTP method for resource."
  default     = "POST"
}

variable "lambda_invoke_arn" {
  type        = string
  description = "Invoke ARN of the target Lambda."
}

variable "lambda_function_name" {
  type        = string
  description = "Name of target Lambda."
}

variable "stage_name" {
  type        = string
  description = "Deployment stage name."
}
