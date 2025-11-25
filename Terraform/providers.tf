terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "local" {
    path = "output/terraform.tfstate"
  }
}

provider "aws" {
  region                      = var.region
  access_key                  = "test"
  secret_key                  = "test"
  s3_use_path_style           = true
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    apigateway       = var.localstack_endpoint
    cloudwatch       = var.localstack_endpoint
    cloudwatchevents = var.localstack_endpoint
    cloudwatchlogs   = var.localstack_endpoint
    cognitoidp       = var.localstack_endpoint
    ec2              = var.localstack_endpoint
    iam              = var.localstack_endpoint
    lambda           = var.localstack_endpoint
    s3               = var.localstack_endpoint
    sns              = var.localstack_endpoint
    sts              = var.localstack_endpoint
  }
}
