resource "aws_lambda_function" "patient" {
  # Function name derived from selected service (e.g. patient-service -> patient-service-lambda)
  function_name = "${var.service}-lambda"
  package_type  = "Image"
  # Use pre-existing ECR repository URL provided by the CI pipeline that builds images
  # The variable `ecr_repository_url` should be set to the full repo URI (eg. 123456789012.dkr.ecr.us-east-1.amazonaws.com/patient-service)
  image_uri     = "${var.ecr_repository_url}:${var.lambda_image_tag}"
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
// moved into modules/lambda
  name             = var.lambda_alias_name
