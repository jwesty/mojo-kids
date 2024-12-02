output "api_endpoint" {
  value = aws_apigatewayv2_api.mojo_apigateway.api_endpoint
}

output "dynamodb_table_name" {
  value = aws_dynamodb_table.mojo_users_table.name
}