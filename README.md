# bayer-hackathon-microservices-infra

Infrastructure and CI for the patient-service microservice.

This repo contains Terraform modules to provision the networking and runtime for the service, plus GitHub Actions workflows to run Terraform (fmt/validate/plan and manual apply/destroy) using GitHub OIDC for short-lived AWS credentials.

## Architecture (high-level)

- AWS VPC with public and private subnets (NAT gateways for outbound traffic)
- Lambda (container image) deployed into private subnets with appropriate SGs
- API Gateway (HTTP API) fronting the Lambda function
- ECR (container images) — image build & push is expected to happen in a separate repo/pipeline and this infra consumes the image via `ecr_repository_url` + `lambda_image_tag`
- Terraform remote state: S3 bucket + DynamoDB table for locks
- GitHub Actions for CI/CD using OIDC: assume role -> run Terraform / plan / (manual) apply
- Observability: CloudWatch Logs and X-Ray tracing enabled on the Lambda

Example API endpoint (after deploy):

```
https://h164eqq9dl.execute-api.ap-south-1.amazonaws.com/health
```

> Note: this is an example URL — your API endpoint will be the value of the `api_endpoint` output after apply.

## What this repo provisions

- VPC (public/private subnets, IGW, NATs)
- Security Group for Lambda
- IAM role(s) for Lambda and CI (note: the GitHub Actions OIDC role bootstrapping is performed via helper scripts)
- Lambda function (image-based)
- API Gateway HTTP API + integration + permission
- Terraform remote backend is *expected* to be configured and exists outside Terraform (bucket + Dynamo table)

## Security notes

- GitHub Actions uses OIDC to assume an IAM role (no long-lived AWS keys in the repo). Follow the helper scripts to create the OIDC provider and create/update the role trust policy.
- Store sensitive values in GitHub Secrets (role ARN, region, etc.) and non-sensitive configuration in Repository Variables if desired.
- The role used by GH Actions must have permissions to manage the S3 backend and DynamoDB lock table. A minimal inline policy `GitHubActionsTerraformStateAccess` was used in this environment; prefer a managed policy in production.
- Networking hardening (NACLs, security group rules, private-only endpoints, VPC endpoints for S3/ECR, restricted bucket policies, KMS key policies) will be applied as a follow-up.

## Quickstart — prerequisites

- AWS account and IAM privileges to create the resources listed above
- An S3 bucket and DynamoDB table for Terraform remote state (example names used in this repo):
  - S3 bucket: `bayer-hackathon-tfstate`
  - DynamoDB table: `bayer-hackathon-state-ddb`
- GitHub repository variables / secrets in this infra repo:
  - Repository Variables (non-sensitive):
    - `TF_STATE_BUCKET` — e.g. `bayer-hackathon-tfstate`
    - `TF_STATE_KEY` — e.g. `patient-service/terraform.tfstate`
    - `TF_STATE_DYNAMODB` — e.g. `bayer-hackathon-state-ddb`
  - Secrets (sensitive):
    - `AWS_ROLE_TO_ASSUME` — role ARN for GH Actions OIDC assume-role
    - `AWS_REGION` — e.g. `ap-south-1`

## GitHub Actions (CI)

- `Terraform CI` workflow (this repo):
  - Runs `terraform fmt` / `validate` and `plan` on push/PR.
  - Uploads `tfplan` as an artifact. `apply` and `destroy` are manual workflow_dispatch jobs gated by inputs (`run_apply`, `run_destroy`).
  - The workflow uses the repository variables/secrets to configure the Terraform backend at runtime.

- Image build and push is intentionally kept in the application repo (or a separate pipeline). Use the app repo's workflow or the included helper script `scripts/build_and_push_dummy_image.sh` to build and push the image to the ECR repo referenced by `ecr_repository_url`.

## How to initialize and migrate local state to S3 (safe steps)

1. Ensure the S3 bucket and DynamoDB table exist.
2. From the `terraform/` directory run:

```bash
terraform init \
  -backend-config="bucket=bayer-hackathon-tfstate" \
  -backend-config="key=patient-service/terraform.tfstate" \
  -backend-config="region=ap-south-1" \
  -backend-config="dynamodb_table=bayer-hackathon-state-ddb" \
  -reconfigure
```

If Terraform prompts to copy local state into the backend, confirm to migrate your state.

## Build & push image (local)

Build and push the dummy image that the Lambda will use (or use your normal CI pipeline that pushes images to ECR):

```bash
./scripts/build_and_push_dummy_image.sh 381492087649.dkr.ecr.ap-south-1.amazonaws.com/bayer-hackathon-registry latest
```

Confirm the image exists:

```bash
aws ecr describe-images --repository-name bayer-hackathon-registry --image-ids imageTag=latest --region ap-south-1
```

## Deploy (recommended via GitHub Actions)

1. Merge changes to `main` (or manually dispatch the `Terraform CI` workflow).
2. For production apply, dispatch the workflow and set the input `run_apply=true` so the `apply` job runs and applies the previously generated plan.

Notes:
- The workflow uses OIDC and a role to assume; ensure `AWS_ROLE_TO_ASSUME` is set to the role ARN in repo secrets and that the role trust policy allows your repo.
- If Terraform init fails with missing backend values, confirm repository Variables `TF_STATE_BUCKET`, `TF_STATE_KEY`, and `TF_STATE_DYNAMODB` are set.

## Troubleshooting

- Empty S3 bucket: `terraform init` alone won't create state — `terraform apply` writes state to S3. If you see backend-config values empty in Actions logs, ensure repository Variables are populated or the workflow is updated to read secrets.
- 403 / AccessDenied errors when accessing S3/DynamoDB: the role assumed by Actions needs S3 and DynamoDB permissions. Add a policy granting s3:GetObject/PutObject/ListBucket and dynamodb:GetItem/PutItem/DescribeTable.
- Lambda -> ECR AccessDenied: make sure your ECR repository has the required repository policy or that the Lambda service (and executing role) can pull the image. Also ensure the image exists in ECR.

## Files of interest

- `terraform/` — Terraform root and modules
- `.github/workflows/terraform.yml` — CI for Terraform
- `scripts/` — helper scripts (OIDC role trust policy helpers, dummy image build/push)

## Next improvements (planned)

- Harden networking (VPC endpoints for S3/ECR, tighter SG rules, NACLs)
- Move IAM resources (role policies) fully into Terraform so infra is fully declared as code
- Add a gated deployment environment and approvals for production apply
- Replace hardcoded values with repository Variables/Secrets and document rollout steps

---

If you want this README expanded with diagrams (Mermaid) or a deployment checklist, tell me what you'd like and I will add it.
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

OIDC provider and role setup
1. Ensure the account has the GitHub OIDC provider (token.actions.githubusercontent.com). You can create it with the included helper script:

   ```bash
   # run from repo root, replace with your AWS account id
   ./scripts/ensure_oidc_provider.sh 381492087649
   ```

2. Update the role trust policy for the role used by GitHub Actions (example role name: `github-actions-deploy-role`). We included `scripts/update_oidc_trust_policy.sh` to automate this. Example:

   ```bash
   ./scripts/update_oidc_trust_policy.sh github-actions-deploy-role 381492087649 trishnanjan/bayer-hackathon-microservices-infra kalyan2312/patient-service kalyan2312/apointment-service
   ```

3. Add the role ARN (e.g. `arn:aws:iam::381492087649:role/github-actions-deploy-role`) as the repo secret `AWS_ROLE_TO_ASSUME` in this infra repo.


2. Run workflows via GitHub Actions:
   - Open a PR to run the Terraform plan workflow.
   - Merge to `main` (or manually dispatch) to run the Terraform apply workflow.

See the individual workflow YAML files and the top-level `terraform/backend.tf` for backend initialization guidance.
