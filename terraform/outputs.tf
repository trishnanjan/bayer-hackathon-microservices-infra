output "api_endpoint" {
  description = "HTTP API endpoint"
  value       = aws_apigatewayv2_api.http_api.api_endpoint
}

output "ecr_repo_url" {
  description = "ECR repository URL"
  value       = aws_ecr_repository.patient.repository_url
}

output "lambda_function_name" {
  description = "Lambda function name"
  value       = aws_lambda_function.patient.function_name
}
