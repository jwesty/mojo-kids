# api_gateway.tf

resource "aws_apigatewayv2_api" "mojo_apigateway" {
  name          = "${var.app_name}-api-${var.environment}"
  protocol_type = "HTTP"

  cors_configuration {
    allow_headers = ["content-type", "authorization"]
    allow_methods = ["GET", "POST", "OPTIONS"]
    allow_origins = ["*"]
  }
}

resource "aws_cloudwatch_log_group" "api_logs" {
  name              = "/aws/api-gateway/${var.app_name}-${var.environment}"
  retention_in_days = 7
}

resource "aws_apigatewayv2_stage" "mojo_main_stage" {
  api_id = aws_apigatewayv2_api.mojo_apigateway.id
  name   = "$default"
  auto_deploy = true

  default_route_settings {
    throttling_burst_limit = 5000
    throttling_rate_limit  = 10000
    detailed_metrics_enabled = true
  }

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_logs.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip            = "$context.identity.sourceIp"
      requestTime   = "$context.requestTime"
      httpMethod    = "$context.httpMethod"
      routeKey      = "$context.routeKey"
      status        = "$context.status"
      protocol      = "$context.protocol"
      responseLength = "$context.responseLength"
      error         = "$context.error.message"
    })
  }
}

resource "aws_apigatewayv2_integration" "mojo_lambda_integration" {
  api_id = aws_apigatewayv2_api.mojo_apigateway.id
  
  integration_type   = "AWS_PROXY"
  integration_uri    = aws_lambda_function.api.invoke_arn
  integration_method = "POST"
  
  payload_format_version = "2.0"
  timeout_milliseconds   = 30000
}

# Keep both the specific login route and the catch-all route
resource "aws_apigatewayv2_route" "login" {
  api_id    = aws_apigatewayv2_api.mojo_apigateway.id
  route_key = "POST /api/login"
  target    = "integrations/${aws_apigatewayv2_integration.mojo_lambda_integration.id}"
}

resource "aws_apigatewayv2_route" "mojo_routes_all" {
  api_id    = aws_apigatewayv2_api.mojo_apigateway.id
  route_key = "ANY /{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.mojo_lambda_integration.id}"
}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.mojo_apigateway.execution_arn}/*/*"
}