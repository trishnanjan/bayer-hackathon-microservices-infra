terraform {
  backend "s3" {
    bucket         = "bayer-hackathon-tfstate"
    key            = "${var.service}/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "bayer-hackathon-state-ddb"
    encrypt        = true
  }
}
