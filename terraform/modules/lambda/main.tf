resource "aws_lambda_function" "this" {
  function_name = "${var.service}-lambda"
  package_type  = "Image"
  image_uri     = "${var.ecr_repository_url}:${var.lambda_image_tag}"
  role          = var.lambda_role_arn
  memory_size   = 512
  timeout       = 30
  publish       = true

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [var.lambda_sg_id]
  }

  tracing_config { mode = "Active" }

  tags = { Service = var.service }
}

resource "aws_lambda_alias" "prod_alias" {
  name             = var.lambda_alias_name
  function_name    = aws_lambda_function.this.function_name
  function_version = aws_lambda_function.this.version
  description      = "Production alias for ${var.service}"
}

resource "aws_lambda_provisioned_concurrency_config" "pc" {
  function_name                     = aws_lambda_function.this.function_name
  qualifier                         = aws_lambda_alias.prod_alias.name
  provisioned_concurrent_executions = var.provisioned_concurrency_count

  depends_on = [aws_lambda_alias.prod_alias]
}

output "lambda_function_name" {
  value = aws_lambda_function.this.function_name
}

output "lambda_invoke_arn" {
  value = aws_lambda_function.this.invoke_arn
}
