variable "service" { type = string }
variable "ecr_repository_url" { type = string }
variable "lambda_image_tag" { type = string }
// removed alias and provisioned concurrency settings
variable "private_subnet_ids" { type = list(string) }
variable "lambda_sg_id" { type = string }
variable "lambda_role_arn" { type = string }
