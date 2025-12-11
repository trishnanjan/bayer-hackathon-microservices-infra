resource "aws_lambda_function" "patient" {
  # Function name derived from selected service (e.g. patient-service -> patient-service-lambda)
  function_name = "${var.service}-lambda"
  package_type  = "Image"
  image_uri     = "${aws_ecr_repository.patient.repository_url}:${var.lambda_image_tag}"
  role          = aws_iam_role.lambda_role.arn
  memory_size   = 512
  timeout       = 30
  publish       = true

  # Place the Lambda inside the VPC private subnets so execution ENIs are created
  # in the specified AZs (private subnets should be across ap-south-1a and ap-south-1b).
  vpc_config {
    subnet_ids         = [for s in aws_subnet.private : s.id]
    security_group_ids = [aws_security_group.lambda_sg.id]
  }

  tracing_config {
    mode = "Active"
  }

  tags = {
    Service = var.service
  }
}

# Create an alias for safe deployments and enable provisioned concurrency on the alias
resource "aws_lambda_alias" "prod_alias" {
  name             = var.lambda_alias_name
  function_name    = aws_lambda_function.patient.function_name
  function_version = aws_lambda_function.patient.version
  description      = "Production alias for ${var.service}"
}

resource "aws_lambda_provisioned_concurrency_config" "pc" {
  function_name                       = aws_lambda_function.patient.function_name
  qualifier                           = aws_lambda_alias.prod_alias.name
  provisioned_concurrent_executions   = var.provisioned_concurrency_count

  depends_on = [aws_lambda_alias.prod_alias]
}

resource "aws_lambda_permission" "apigw_invoke" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.patient.function_name
  principal     = "apigateway.amazonaws.com"
}
