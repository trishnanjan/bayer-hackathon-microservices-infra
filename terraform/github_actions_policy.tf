//Deployed Manually
//To DO: Automate this deployment using Terraform.

variable "github_actions_role_arn" {
  type        = string
  description = "ARN of the GitHub Actions IAM role to attach the Terraform state access policy to. Example: arn:aws:iam::123456789012:role/github-actions-deploy-role"
  default     = ""
}

locals {
  # extract role name from ARN (arn:aws:iam::account:role/ROLE_NAME)
  github_actions_role_name = length(var.github_actions_role_arn) > 0 ? element(split("/", var.github_actions_role_arn), 1) : ""
}

data "aws_iam_role" "github_actions_role" {
  count = local.github_actions_role_name != "" ? 1 : 0
  name  = local.github_actions_role_name
}

resource "aws_iam_policy" "github_actions_tfstate" {
  name        = "GitHubActionsTerraformStateAccess"
  description = "Allows GitHub Actions OIDC role to read/write Terraform state in S3 and use DynamoDB for locking"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ],
        Resource = [
          "arn:aws:s3:::bayer-hackathon-tfstate",
          "arn:aws:s3:::bayer-hackathon-tfstate/*"
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:DeleteItem",
          "dynamodb:DescribeTable",
          "dynamodb:Query",
          "dynamodb:UpdateItem",
          "dynamodb:Scan"
        ],
        Resource = [
          "arn:aws:dynamodb:${var.aws_region}:${data.aws_caller_identity.current.account_id}:table/bayer-hackathon-state-ddb"
        ]
      }
    ]
  })
}

data "aws_caller_identity" "current" {}

resource "aws_iam_role_policy_attachment" "attach" {
  count      = length(data.aws_iam_role.github_actions_role) > 0 ? 1 : 0
  role       = data.aws_iam_role.github_actions_role[0].name
  policy_arn = aws_iam_policy.github_actions_tfstate.arn
}
