# SBW ClickStream – Terraform Production AWS (Kiến trúc V10, PrivateLink + ALB)

Triển khai hạ tầng theo `README.md` gốc và sơ đồ V10, với các điểm đã chốt:
- Mặc định **không bật NAT Gateway**
- Chỉ **2 bucket** (media + raw); ETL ghi trực tiếp vào Postgres
- Lambda **không** gắn VPC, dùng **PrivateLink + NLB nội bộ** tới ALB/DWH/Shiny
- **DWH và R Shiny chung 1 EC2**
- **Amplify bật mặc định**

## 0) Chuẩn bị
1) Cài Terraform >= 1.5, AWS CLI; kiểm tra `terraform version`, `aws --version`.
2) Đăng nhập AWS (`aws configure` hoặc profile sẵn); đặt `aws_profile` trong `prod.auto.tfvars`.
3) Quyền cần có: VPC/Subnet/IGW/NAT (tùy chọn), IAM, Lambda, API Gateway, EventBridge, EC2, S3, SNS, Cognito, Amplify, ALB/NLB/VPC endpoints.
4) Chọn region ≥ 2 AZ (vd `ap-southeast-1`): `aws ec2 describe-availability-zones --region <region>`.
5) Chuẩn bị file ZIP Lambda, cập nhật `lambda_ingest_zip`, `lambda_etl_zip`.
6) SSH/SSM: điền `oltp_key_name`, `analytics_key_name` hoặc để trống dùng Session Manager.
7) Amplify: repo URL, PAT, branch; giữ `enable_amplify = true` nếu muốn bật.

## 1) Remote state (khuyến nghị)
Tạo S3 + DynamoDB cho state/lock rồi init:
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

## 2) Điền biến (`prod.auto.tfvars`)
Chỉnh `Terraform/ProductionAWS/prod.auto.tfvars`:
- Region/profile: `region`, `aws_profile`
- Bucket: `bucket_media`, `bucket_raw`
- Lambda: `lambda_ingest_zip`, `lambda_etl_zip`
- Mạng: `enable_nat_gateway` (mặc định `false`), `allowed_admin_cidrs` (ai được vào Shiny ALB)
- EC2: key pair, AMI tùy chọn, dung lượng đĩa
- Cognito/SNS: tên pool/client/topic
- Amplify: repo, token, branch (bật mặc định)
- Logging: `log_retention_days`

## 3) Triển khai
```bash
terraform -chdir=Terraform/ProductionAWS init   # 1 lần cho backend
terraform -chdir=Terraform/ProductionAWS plan   -var-file=prod.auto.tfvars
terraform -chdir=Terraform/ProductionAWS apply  -var-file=prod.auto.tfvars
```

## 4) Output chính
- `api_invoke_url` – endpoint API Gateway (POST /click)
- `lambda_functions` – ARN ingest + etl
- `s3_buckets` – tên media/raw
- `cognito.user_pool_id`, `cognito.client_id`
- `sns_topic_arn`
- `shiny_alb_dns` – DNS ALB nội bộ cho Shiny
- `privatelink` – service name, endpoint ID/DNS, NLB DNS (đường Lambda→DWH/Shiny qua PrivateLink)
- `ec2_instances` – ID OLTP và DWH+Shiny
- ID subnet/VPC, endpoint S3

## 5) Lưu ý kết nối & bảo mật
- NAT tắt mặc định; truy cập S3 từ subnet private dùng Gateway Endpoint.
- Lambda **không** gắn VPC; DWH/Shiny lộ ra qua NLB nội bộ + Endpoint Service (PrivateLink). Truy cập Shiny admin qua ALB nội bộ port 80, giới hạn bởi `allowed_admin_cidrs`.
- EC2 không IP public; dùng SSM hoặc VPN/DirectConnect.
- S3 chặn public, bật SSE và versioning.

## 6) Gợi ý tiếp theo
- Thay `shiny_user_data` bằng script cài Postgres + R + Shiny + reverse proxy.
- Thêm cảnh báo CloudWatch (Lambda errors, API 5xx, EC2 CPU/disk, S3 errors).
- Nếu cần domain: thêm Route53/ACM cho API/CloudFront/ALB.
