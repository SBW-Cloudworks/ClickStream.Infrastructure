# SBW ClickStream – Production AWS Terraform (Architecture V10, PrivateLink + ALB)

This stack follows the project source of truth (`README.md`) and the V10 diagram, with the requested changes:
- NAT Gateway **disabled by default**
- Only **two buckets** (media + raw); ETL writes directly to Postgres
- Lambdas stay **outside the VPC**, with a **PrivateLink + internal NLB** path toward the internal ALB/DWH/Shiny
- Data Warehouse **shares the same EC2** as R Shiny
- **Amplify enabled by default**

## 0) Before you run
1) Install Terraform >= 1.5 and AWS CLI; verify `terraform version`, `aws --version`.
2) Login via `aws configure` or existing profile; set `aws_profile` in `prod.auto.tfvars`.
3) Permissions: create VPC/Subnets/IGW/NAT (optional), IAM roles/policies, Lambda, API Gateway, EventBridge, EC2, S3, SNS, Cognito, Amplify, ALB/NLB/VPC endpoints.
4) Pick a region with ≥2 AZs (e.g., `ap-southeast-1`); check via `aws ec2 describe-availability-zones --region <region>`.
5) Prepare Lambda ZIPs and point `lambda_ingest_zip`, `lambda_etl_zip` to real files.
6) SSH/SSM: set `oltp_key_name`, `analytics_key_name` (or leave empty and use Session Manager).
7) Amplify: provide repo URL, PAT, branch; leave `enable_amplify = true` unless you want to disable.

## 1) Remote state (recommended)
Create an S3 bucket + DynamoDB table for state/lock, then init:
```bash
aws s3api create-bucket --bucket <tfstate-bucket> --region <region> --create-bucket-configuration LocationConstraint=<region>
aws dynamodb create-table --table-name <lock-table> \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST

terraform -chdir=Terraform/ProductionAWS init \
  -backend-config="bucket=<tfstate-bucket>" \
  -backend-config="key=clickstream/prod/terraform.tfstate" \
  -backend-config="region=<region>" \
  -backend-config="dynamodb_table=<lock-table>"
```

## 2) Set variables (`prod.auto.tfvars`)
Edit `Terraform/ProductionAWS/prod.auto.tfvars` with your real values. Key fields:
- Region/profile: `region`, `aws_profile`
- Buckets: `bucket_media`, `bucket_raw`
- Lambda zips: `lambda_ingest_zip`, `lambda_etl_zip`
- Network: `enable_nat_gateway` (defaults to `false`), `allowed_admin_cidrs` (who can reach Shiny ALB)
- EC2: key pairs, optional AMI overrides, volume sizes
- Cognito/SNS: names for pool/client/topic
- Amplify: repo URL, token, branch (enabled by default)
- Logging: `log_retention_days`

## 3) Deploy
```bash
terraform -chdir=Terraform/ProductionAWS init   # once per backend config
terraform -chdir=Terraform/ProductionAWS plan   -var-file=prod.auto.tfvars
terraform -chdir=Terraform/ProductionAWS apply  -var-file=prod.auto.tfvars
```

## 4) Outputs you’ll get
- `api_invoke_url` – API Gateway endpoint (POST /click)
- `lambda_functions` – ingest + etl ARNs
- `s3_buckets` – media/raw names
- `cognito.user_pool_id`, `cognito.client_id`
- `sns_topic_arn`
- `shiny_alb_dns` – internal ALB DNS for Shiny
- `privatelink` – service name, endpoint ID/DNS, NLB DNS (for Lambda-to-DWH/Shiny over PrivateLink)
- `ec2_instances` – OLTP and DWH+Shiny instance IDs
- subnet/VPC IDs, S3 VPC endpoint ID

## 5) Notes on connectivity and security
- NAT is off by default; S3 access from private subnets uses the S3 Gateway Endpoint.
- Lambdas are configured **without VPC attachment**; the DWH/Shiny path is exposed via an internal NLB + Endpoint Service to align with the requested PrivateLink pattern, while Shiny admin access flows through an internal ALB (port 80) restricted by `allowed_admin_cidrs`.
- EC2 instances are private-only (no public IP). Use SSM Session Manager or VPN/DirectConnect for access.
- S3 buckets block public access, have SSE + versioning enabled.

## 6) Next ideas
- Swap `shiny_user_data` with a real bootstrap script (Postgres + R + Shiny + reverse proxy).
- Add alarms (Lambda errors, API 5xx, EC2 CPU/disk, S3 errors).
- Add Route53/ACM for custom domains (API/CloudFront/ALB) if needed.
