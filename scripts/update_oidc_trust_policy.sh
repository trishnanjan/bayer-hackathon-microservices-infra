#!/usr/bin/env bash
set -euo pipefail

# update_oidc_trust_policy.sh
# Usage: ./update_oidc_trust_policy.sh <role-name> <account-id> <repo1> [<repo2> ...]
# Example:
# ./update_oidc_trust_policy.sh github-actions-deploy-role 381492087649 trishnanjan/bayer-hackathon-microservices-infra kalyan2312/patient-service kalyan2312/apointment-service

if [ "$#" -lt 3 ]; then
  echo "Usage: $0 <role-name> <aws-account-id> <owner/repo> [<owner/repo> ...]"
  exit 1
fi

ROLE_NAME="$1"
ACCOUNT_ID="$2"
shift 2
REPOS=("$@")

OIDC_PROVIDER_ARN="arn:aws:iam::${ACCOUNT_ID}:oidc-provider/token.actions.githubusercontent.com"
TRUST_FILE="/tmp/${ROLE_NAME}-trust-policy.json"

# Build the 'sub' list entries (allow any branch in each repo)
# We'll create a comma-separated list of JSON strings, then strip trailing comma
SUBJECTS=""
for repo in "${REPOS[@]}"; do
  SUBJECTS+="\"repo:${repo}:ref:refs/heads/*\","
done
# remove trailing comma
SUBJECTS=${SUBJECTS%,}

cat > "$TRUST_FILE" <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": { "Federated": "${OIDC_PROVIDER_ARN}" },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringLike": {
          "token.actions.githubusercontent.com:sub": [
            ${SUBJECTS}
          ]
        },
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        }
      }
    }
  ]
}
EOF

echo "Wrote trust policy to: $TRUST_FILE"

# Show the trust policy
cat "$TRUST_FILE"

echo
read -p "About to update assume role policy for role '$ROLE_NAME' in account $ACCOUNT_ID. Continue? [y/N] " yn
case "$yn" in
  [Yy]*) ;;
  *) echo "Aborted."; exit 1;;
esac

# Apply the trust policy
aws iam update-assume-role-policy --role-name "$ROLE_NAME" --policy-document file://"$TRUST_FILE"

echo "Updated assume-role policy for role: $ROLE_NAME"

echo "To verify, run:"
echo "  aws iam get-role --role-name $ROLE_NAME --query 'Role.AssumeRolePolicyDocument' --output json"

echo "Then test assuming the role from GitHub Actions by running a workflow that uses 'aws-actions/configure-aws-credentials@v2' with id-token: write permissions."
