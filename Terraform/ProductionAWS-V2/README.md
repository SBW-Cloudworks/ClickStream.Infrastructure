# SBW ClickStream - Production AWS Terraform (Architecture V10, PrivateLink + ALB)

This stack matches the V10 diagram with these decisions:

- NAT Gateway disabled by default
- Only two buckets (media + raw); ETL writes directly to Postgres
- Lambdas stay outside the VPC, reaching DWH/Shiny via PrivateLink + internal NLB
- DWH + R Shiny on the same EC2
- Amplify enabled by default

## 0) Before you run

**1) Install Terraform >= 1.5 and AWS CLI**

```bash
winget install --id HashiCorp.Terraform -e
winget install --id Amazon.AWSCLI -e
```

Verify the install status

```
terraform version
aws --version
```

**2) Configure AWS CLI profile:**

- Default profile: run `aws configure`, enter Access Key, Secret, Region, Output; then set `aws_profile = ""` in `prod.auto.tfvars` to use that default profile. Terraform will automatically pick up the default profile; nothing else is needed.
- Named profile (recommended): run `aws configure --profile <name>` (e.g., `prod`); then set `aws_profile = "<name>"` in `prod.auto.tfvars`.

1.  Create User

![alt text](img/image.png)
![alt text](img/image-1.png)
![alt text](img/image-2.png)
![alt text](img/image-3.png) 2) Create Key
![alt text](img/image-4.png)
![alt text](img/image-5.png)

**3) Permissions:**
create VPC/Subnets/IGW/NAT (optional), IAM roles/policies, Lambda, API Gateway, EventBridge, EC2, S3, SNS, Cognito, Amplify, ALB/NLB/VPC endpoints.
![alt text](img/image-6.png)
![alt text](img/image-7.png)

**4) Pick a region with at least 2 AZs (for example `ap-southeast-1`); check:**

```bash
aws configure set region ap-southeast-1 --profile <aws_profile>
aws configure set output json --profile <aws_profile>

```

**5) Prepare Lambda ZIPs**

- Package each Lambda into a ZIP with its dependencies:

- For Python:
```
cd lambda/ingest
pip install -r requirements.txt -t .
zip -r ../../artifacts/lambda_ingest.zip .
```
```
cd ../etl
pip install -r requirements.txt -t .
zip -r ../../artifacts/lambda_etl.zip .
```
> (Adjust paths as needed; ensure the handler file is inside the zip at root.)

- Update `Terraform/ProductionAWS-V2/prod.auto.tfvars` to point to those ZIPs:
```
lambda_ingest_zip = "../../artifacts/lambda_ingest.zip"
lambda_etl_zip    = "../../artifacts/lambda_etl.zip"
```
Sanity check the paths exist:
**PowerShell:** `Test-Path "../../artifacts/lambda_ingest.zip"`
**Bash:** `ls ../../artifacts/lambda_ingest.zip`

After this, Terraform will upload those ZIPs when creating the Lambda functions.


**6) SSH/SSM**

- set `oltp_key_name`, `analytics_key_name` (or leave empty and use Session Manager).

**7) Amplify**

- provide repo URL, PAT, branch; keep `enable_amplify = true` unless you want to disable.

## 1) Remote state (recommended)

1.1) Create an S3 bucket + DynamoDB table for state/lock:

```bash
aws s3api create-bucket --bucket <tfstate-bucket> --region <region> --create-bucket-configuration LocationConstraint=<region>
aws dynamodb create-table --table-name <lock-table> \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST

terraform -chdir=Terraform/ProductionAWS-V2 init \
  -backend-config="bucket=<tfstate-bucket>" \
  -backend-config="key=clickstream/prod/terraform.tfstate" \
  -backend-config="region=<region>" \
  -backend-config="dynamodb_table=<lock-table>"
```

1.2) Optional: harden the state bucket (versioning, SSE, TLS-only policy as in `state-bucket-policy.json`).

## 2) Set variables (prod.auto.tfvars)

Edit `Terraform/ProductionAWS-V2/prod.auto.tfvars` with your real values.

### 2.1) Config toggles (ON/OFF)

- `enable_nat_gateway` (default `false`) - leave off unless you need outbound internet from private subnets.
- `enable_amplify` (default `true`) - turn off only if you are not deploying the frontend via Amplify.

### 2.2) Resource identifiers / names (not secrets)

- AWS: `region`, `aws_profile`

```hcl
region      = "ap-southeast-1"
aws_profile = "prod"
```

- S3 buckets: `bucket_media`, `bucket_raw`

```hcl
bucket_media = "sbw-clickstream-media-prod"
bucket_raw   = "sbw-clickstream-raw-prod"
```

- Network access: `allowed_admin_cidrs`

```hcl
allowed_admin_cidrs = ["203.0.113.0/24"]
```

- EC2 access/images: `oltp_key_name`, `analytics_key_name`, optional `oltp_ami_id`, `analytics_ami_id`, and volume sizes (key names are just the EC2 Key Pair names you created; no private key material is stored here)

```hcl
oltp_key_name            = "prod-key"
analytics_key_name       = "prod-key"
oltp_ami_id              = ""
analytics_ami_id         = ""
oltp_root_volume_gb      = 50
analytics_root_volume_gb = 200
```

- Cognito/SNS names: `cognito_user_pool_name`, `cognito_client_name`, `sns_topic_name`

```hcl
cognito_user_pool_name = "clickstream-users"
cognito_client_name    = "clickstream-app-client"
sns_topic_name         = "clickstream-prod-alerts"
```

- Amplify repo/branch: `amplify_repo_url`, `amplify_branch_name`

```hcl
amplify_repo_url    = "https://github.com/example-org/example-repo"
amplify_branch_name = "main"
```

- Other: `log_retention_days`

```hcl
log_retention_days = 30
```

### 2.3) Secrets / artifacts

- Lambda packages: `lambda_ingest_zip`, `lambda_etl_zip` (paths to your built ZIPs)

```hcl
lambda_ingest_zip = "../../artifacts/lambda_ingest.zip"
lambda_etl_zip    = "../../artifacts/lambda_etl.zip"
```

- Amplify: `amplify_access_token`

```hcl
amplify_access_token = "REPLACE_WITH_GH_PAT"
```

> AWS access keys are not stored here; they live in your AWS profile/credential store referenced by `aws_profile`.

## 3) Deploy

```bash
terraform -chdir=Terraform/ProductionAWS-V2 init   # once per backend config
terraform -chdir=Terraform/ProductionAWS-V2 plan   -var-file=prod.auto.tfvars
terraform -chdir=Terraform/ProductionAWS-V2 apply  -var-file=prod.auto.tfvars
```

## 4) Outputs you will get

- `api_invoke_url` - API Gateway endpoint (POST /click)
- `lambda_functions` - ingest + etl ARNs
- `s3_buckets` - media/raw names
- `cognito.user_pool_id`, `cognito.client_id`
- `sns_topic_arn`
- `shiny_alb_dns` - internal ALB DNS for Shiny
- `privatelink` - service name, endpoint ID/DNS, NLB DNS (for Lambda-to-DWH/Shiny over PrivateLink)
- `ec2_instances` - OLTP and DWH+Shiny instance IDs
- subnet/VPC IDs, S3 VPC endpoint ID

## 5) Notes on connectivity and security

- NAT is off by default; S3 access from private subnets uses the S3 Gateway Endpoint.
- Lambdas are configured without VPC attachment; the DWH/Shiny path is exposed via an internal NLB + Endpoint Service to align with the requested PrivateLink pattern, while Shiny admin access flows through an internal ALB (port 80) restricted by `allowed_admin_cidrs`.
- EC2 instances are private-only (no public IP). Use SSM Session Manager or VPN/DirectConnect for access.
- S3 buckets block public access, have SSE + versioning enabled.

## 6) Next ideas

- Swap `shiny_user_data` with a real bootstrap script (Postgres + R + Shiny + reverse proxy).
- Add alarms (Lambda errors, API 5xx, EC2 CPU/disk, S3 errors).
- Add Route53/ACM for custom domains (API/CloudFront/ALB) if needed.
