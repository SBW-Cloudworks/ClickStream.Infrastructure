variable "function_name" {
  type        = string
  description = "Lambda function name."
}

variable "role_arn" {
  type        = string
  description = "IAM role ARN for Lambda."
}

variable "handler" {
  type        = string
  description = "Lambda handler."
}

variable "runtime" {
  type        = string
  description = "Lambda runtime."
}

variable "filename" {
  type        = string
  description = "Path to lambda zip file."
}

variable "memory_size" {
  type        = number
  description = "Lambda memory size."
  default     = 128
}

variable "timeout" {
  type        = number
  description = "Lambda timeout in seconds."
  default     = 3
}

variable "environment_variables" {
  type        = map(string)
  description = "Environment variables for Lambda."
  default     = {}
}
