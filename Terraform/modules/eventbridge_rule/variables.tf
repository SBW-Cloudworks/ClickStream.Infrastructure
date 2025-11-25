variable "name" {
  type        = string
  description = "Rule name."
}

variable "schedule_expression" {
  type        = string
  description = "EventBridge schedule expression."
}

variable "lambda_arn" {
  type        = string
  description = "Target lambda ARN."
}

variable "lambda_name" {
  type        = string
  description = "Target lambda name."
}

variable "target_id" {
  type        = string
  description = "Target identifier."
}
