resource "aws_lambda_function" "lambda" {
  filename      = var.lambda_execute_filename
  function_name = var.lambda_function_name
  role          = var.lambda_function_role
  handler       = var.lambda_handler
  runtime       = var.lambda_runtime
  depends_on = [  aws_cloudwatch_log_group.example ]
  environment {
    variables = var.lambda_env_variables
  }
}

# This is to optionally manage the CloudWatch Log Group for the Lambda Function.
# If skipping this resource configuration, also add "logs:CreateLogGroup" to the IAM policy below.
resource "aws_cloudwatch_log_group" "example" {
  name              = "/aws/lambda/${var.lambda_function_name}"
  retention_in_days = 14
}

output "log_group_name" {
  value = aws_cloudwatch_log_group.example.name
}

output "aws_lambda_function_arn" {
  value = aws_lambda_function.lambda.arn
}