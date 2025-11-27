![sbwCloudworks](docs/swbCloudworksBanner.png)
# Clickstream Analytics Platform Architecture

![ClickStreamDiagramV8](docs/ClickStreamDiagramV8.png)

## 🌐 Overview

This project implements a **Clickstream Analytics System** using AWS services with a **Batch Processing Architecture**. It handles data collection, raw storage, periodic ETL processing, and analytics visualization using a self-managed PostgreSQL + R Shiny Server running on EC2.

The system emphasizes **low cost**, **scalability**, **security**, and **full control of the data warehouse layer**.

---

## 📌 Architecture Components

The system is built using the following AWS services:

* **Frontend Hosting:** AWS Amplify Hosting (CloudFront integrated)
* **Authentication:** Amazon Cognito (User Pool)
* **API Layer:** Amazon API Gateway (HTTP API)
* **Data Ingestion:** AWS Lambda (Clickstream ingest)
* **Raw Data Lake:** Amazon S3 (Raw Layer)
* **Batch Scheduler:** Amazon EventBridge (Cron Job)
* **ETL Processor:** AWS Lambda ETL
* **Private Connectivity:** VPC Endpoint Interface
* **Internal Routing:** Internal ALB
* **Data Warehouse & Analytics:** EC2 running PostgreSQL + R Shiny Server
* **Visualization:** Shiny Dashboard

---

## 🔄 Data and Process Flow

### 1. **User Interaction**
Users access the website through **Amplify + CloudFront**, which delivers static web assets with low latency.

### 2. **Event Collection**
A JavaScript SDK embedded in the frontend sends user interaction events (clicks, views, searches) to **Amazon API Gateway**.

### 3. **Ingestion Layer**
API Gateway invokes an **AWS Lambda** function that validates and stores raw clickstream data into **Amazon S3 (Raw Layer)**.

### 4. **Batch Processing (ETL)**

* **Amazon EventBridge** triggers the ETL Lambda function every 60 minutes.
* The Lambda function reads raw logs from S3, performs cleaning, transformation, and normalization.
* Processed data is written to **S3 Processed Layer** and loaded into the **EC2 Data Warehouse**.

### 5. **Analytics & Visualization**
An **R Shiny Server** on EC2 queries the Data Warehouse to provide dashboards displaying product popularity, customer behavior, sales funnels, and traffic trends.

---

## 🗂 Recommended Project Folder Structure

```
📦 Clickstream-Analytics
 ┣ 📂 infrastructure
 ┃ ┗ 📜 terraform
 ┣ 📂 frontend
 ┃ ┗ 📜 React/NextJS source
 ┣ 📂 lambda
 ┃ ┣ 📜 ingest.py
 ┃ ┗ 📜 etl.py
 ┣ 📂 scripts
 ┃ ┗ 📜 ec2-setup.sh
 ┣ 📂 shiny
 ┃ ┗ 📜 app.R
 ┗ 📜 README.md
```

---

## 🏗 Deployment Workflow

1. Deploy Amplify Hosting
2. Configure Cognito User Pool
3. Create API Gateway HTTP API
4. Deploy Lambda Ingest and ETL
5. Create S3 Raw Layer bucket
6. Set up EventBridge cron
7. Create VPC Endpoint + Internal ALB
8. Launch EC2 and install PostgreSQL + Shiny
9. Configure ALB → EC2 routing
10. Test ingestion → ETL → database workflow
11. Access the Shiny dashboard

---

## 🔐 Integration and Security Controls

* **Authentication & Authorization**: Amazon Cognito manages secure user sign-in and token-based access to APIs.
* **Least-privilege IAM Policies** are enforced for Lambda, API Gateway, EC2, and S3 access.
* **Operational Metrics & Alerts** are configured in Amazon CloudWatch and forwarded to Amazon SNS.
* **Private subnets** ensure no direct public access to the Data Warehouse or Shiny workloads.
* **S3 VPC Endpoint** ensures internal-only communication without exposing resources to the internet.

---

## 📊 Key Features of the System

### ✔ Amplify Hosting
* Automatic CI/CD
* CloudFront + S3 integrated
* No server maintenance

### ✔ Cognito Authentication
* Secure JWT workflow
* Easy integration with API Gateway

### ✔ Serverless Ingestion (API Gateway + Lambda)
* Low cost
* Automatically scalable

### ✔ S3 Raw Layer
* Durable, cheap, ideal for Data Lake

### ✔ EventBridge Batch Scheduling
* Flexible cron
* Ideal for periodic ETL processing

### ✔ Lambda ETL
* Stateless, scalable ETL jobs
* Converts NoSQL → SQL

### ✔ VPC Endpoint + Internal ALB
* Ensures secure private network communication
* No exposure of EC2 to the internet

### ✔ EC2 PostgreSQL + Shiny
* Full control of Data Warehouse
* Ideal for data analytics dashboards