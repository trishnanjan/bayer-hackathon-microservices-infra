# bayer-hackathon-microservices-infra

This repository contains infrastructure and CI for the patient-service application.

Contents
- `terraform/` — Terraform code to provision VPC, ECR, IAM roles, Lambda (container image), API Gateway, CloudWatch, X-Ray, NAT Gateways, and backend/bootstrap helpers.
- `.github/workflows/` — GitHub Actions workflows for building/pushing Docker images, running Terraform plan/apply, and updating the Lambda image.
- `scripts/create_github_oidc_role.sh` — helper to create an IAM role that GitHub Actions can assume via OIDC.

Quick start
1. Add repository secrets in the infra repo (Settings → Secrets → Actions):
   - `AWS_ROLE_TO_ASSUME` — ARN of the role GitHub Actions will assume (created via script)
   - `AWS_REGION` — `ap-south-1`
   - `TF_STATE_BUCKET` — `bayer-hackathon-tfstate` (you said you created this)
   - `TF_STATE_DYNAMODB` — `bayer-hackathon-state-ddb`
   - `TF_STATE_KEY` — `patient-service/terraform.tfstate`
   - `ECR_REGISTRY`, `ECR_REPOSITORY`, `LAMBDA_FUNCTION_NAME` (used by workflows)

2. Run workflows via GitHub Actions:
   - Open a PR to run the Terraform plan workflow.
   - Merge to `main` (or manually dispatch) to run the Terraform apply workflow.

See the individual workflow YAML files and the top-level `terraform/backend.tf` for backend initialization guidance.
