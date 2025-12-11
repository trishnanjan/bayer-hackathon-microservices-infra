module "vpc" {
  source         = "./modules/vpc"
  service        = var.service
  vpc_cidr       = var.vpc_cidr
  public_subnets = var.public_subnets
  private_subnets = var.private_subnets
  azs = var.azs
}

module "iam" {
  source  = "./modules/iam"
  service = var.service
}

module "lambda" {
  source = "./modules/lambda"
  service = var.service
  ecr_repository_url = var.ecr_repository_url
  lambda_image_tag = var.lambda_image_tag
  # alias and provisioned concurrency removed
  private_subnet_ids = module.vpc.private_subnet_ids
  lambda_sg_id = module.vpc.lambda_sg_id
  lambda_role_arn = module.iam.lambda_role_arn
}

module "apigw" {
  source = "./modules/apigw"
  service = var.service
  lambda_invoke_arn = module.lambda.lambda_invoke_arn
  lambda_function_name = module.lambda.lambda_function_name
}

output "api_endpoint" {
  value = module.apigw.api_endpoint
}

output "ecr_repo_url" {
  value = var.ecr_repository_url
}

output "lambda_function_name" {
  value = module.lambda.lambda_function_name
}
