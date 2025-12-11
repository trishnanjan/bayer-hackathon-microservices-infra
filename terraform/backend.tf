/*
  Backend configuration for the main Terraform code.

  IMPORTANT: You cannot configure this backend until the S3 bucket and DynamoDB table
  exist. If you already created them, initialize Terraform with the backend-config options.

*/

/* Example backend block if you prefer to commit it with real values (NOT recommended):
terraform {
  backend "s3" {
    bucket         = "REPLACE_WITH_BUCKET"
    key            = "patient-service/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "REPLACE_WITH_DDB_TABLE"
    encrypt        = true
  }
}
*/
