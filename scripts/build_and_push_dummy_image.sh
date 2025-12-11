#!/usr/bin/env bash
set -euo pipefail

# Usage:
# ./scripts/build_and_push_dummy_image.sh <ecr_repository_url> [tag]
# Example:
# ./scripts/build_and_push_dummy_image.sh 381492087649.dkr.ecr.ap-south-1.amazonaws.com/bayer-hackathon-registry v1.0.0

if [ "$#" -lt 1 ]; then
  echo "Usage: $0 <ecr_repository_url> [tag]"
  exit 1
fi

ECR_URL="$1"
TAG="${2:-latest}"

echo "Building dummy lambda image -> ${ECR_URL}:${TAG}"

cd "$(dirname "$0")/dummy-lambda"

# Login to ECR (requires AWS CLI configured)
AWS_REGION=$(aws configure get region || echo "ap-south-1")
ACCOUNT_ID=$(echo "$ECR_URL" | cut -d'.' -f1)

echo "Logging into ECR in region ${AWS_REGION} for account ${ACCOUNT_ID}"
aws ecr get-login-password --region "$AWS_REGION" | docker login --username AWS --password-stdin "${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

docker build -t "${ECR_URL}:${TAG}" .

echo "Pushing image to ${ECR_URL}:${TAG}"
docker push "${ECR_URL}:${TAG}"

echo "Done. Image pushed: ${ECR_URL}:${TAG}"
