variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "public_subnets" {
  type = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnets" {
  type = list(string)
  default = ["10.0.101.0/24", "10.0.102.0/24"]
}

variable "lambda_image_tag" {
  type    = string
  default = "latest"
}

variable "service" {
  type    = string
  default = "patient-service"
  description = "Logical service name (used to name resources and tags). Example: patient-service or apointment-service"
}

variable "ecr_repository" {
  type    = string
  default = "patient-service"
  description = "ECR repository name where the container image is stored. This repo will be created if missing."
}

variable "ecr_repository_url" {
  type        = string
  default     = "381492087649.dkr.ecr.ap-south-1.amazonaws.com/bayer-hackathon-registry"
  description = "Full ECR repository URI (account.dkr.ecr.<region>.amazonaws.com/<repo>). If provided, Terraform will use this existing repo's URL for the Lambda image; the repo creation is handled by a separate pipeline."
}

variable "lambda_function_name" {
  type    = string
  default = "patient-service-lambda"
}

variable "azs" {
  type = list(string)
  default = ["ap-south-1a", "ap-south-1b"]
  description = "Availability zones to use for subnet placement (ordered)"
}

variable "provisioned_concurrency_count" {
  type    = number
  default = 2
  description = "Number of provisioned concurrency units for the Lambda alias"
}

variable "lambda_alias_name" {
  type    = string
  default = "prod"
  description = "Alias name to publish for safe deployments (used with provisioned concurrency)"
}
