#!/usr/bin/env bash
set -euo pipefail

# ensure_oidc_provider.sh
# Creates the GitHub Actions OIDC provider if it does not exist.
# Usage: ./scripts/ensure_oidc_provider.sh <aws-account-id>

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <aws-account-id>"
  exit 1
fi

ACCOUNT_ID="$1"
OIDC_URL="https://token.actions.githubusercontent.com"
THUMBPRINT="6938fd4d98bab03faadb97b34396831e3780aea1"

echo "Checking for existing OIDC providers..."
EXISTING=$(aws iam list-open-id-connect-providers --output json)
if echo "$EXISTING" | grep -q "token.actions.githubusercontent.com"; then
  echo "OIDC provider for GitHub Actions already exists."
  aws iam list-open-id-connect-providers --output json
  exit 0
fi

echo "Creating OIDC provider for GitHub Actions..."
arn=$(aws iam create-open-id-connect-provider \
  --url $OIDC_URL \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list $THUMBPRINT \
  --query 'OpenIDConnectProviderArn' --output text)

echo "Created OIDC provider: $arn"

