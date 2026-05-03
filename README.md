# SWE455 Project – Infrastructure

This repository contains the Terraform-based infrastructure for the File Validation Service developed for the SWE 455 Cloud Applications Engineering course.

---

## 🧱 Overview

The infrastructure provisions a fully cloud-native, serverless backend architecture on AWS, supporting:

- File upload and validation services
- Asynchronous processing
- Scalable, stateless compute
- Fully automated deployment and teardown

---

## 🏗️ Architecture

The system follows an event-driven design:

Client → API Gateway → Upload Lambda → S3 → SQS → Validator Lambda → DynamoDB

### Components:
- **API Gateway** – exposes REST endpoint (`POST /upload`)
- **AWS Lambda**
  - Upload Service
  - Validator Service
- **Amazon S3**
  - Upload bucket (file storage)
  - Artifact bucket (deployment packages)
- **Amazon SQS** – asynchronous message queue
- **Amazon DynamoDB** – stores validation results
- **IAM** – roles and permissions for secure service interaction

---

## ⚙️ Infrastructure as Code

All resources are provisioned using **Terraform**, ensuring:

- Reproducible environments
- No manual AWS configuration
- Full compliance with project requirements

---

## 🔁 Automation

### Terraform Automation
- `terraform apply` → deploys full system
- `terraform destroy` → tears down all resources (including S3 objects)

### CI/CD Integration
Service repositories (upload & validator) include GitHub Actions pipelines that:
- Build application artifacts (`.zip`)
- Upload them to the S3 artifact bucket automatically on push

---

## 🔐 Configuration Management

Configuration is handled using:
- Terraform variables
- AWS IAM roles
- Lambda environment variables (no hardcoded values)

---

## 🚀 Usage

### Deploy infrastructure:
```bash
terraform init
terraform apply