/*
  ECR repository is managed by a separate CI pipeline in another repository.
  This repo expects the full ECR repository URI to be provided via
  the variable `ecr_repository_url` (see variables.tf). Do NOT create the
  ECR repository here to avoid conflicts with the image build pipeline.

  Example usage (set via TF var or secret):
    ecr_repository_url = "123456789012.dkr.ecr.us-east-1.amazonaws.com/patient-service"

*/
