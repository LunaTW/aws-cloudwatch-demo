//locals {
//  environment_map = var.lambda_env_variables == null ? [] : [var.lambda_env_variables]
//}

resource "aws_lambda_function" "lambda" {
  filename         = var.lambda_execute_filename
  function_name    = var.lambda_function_name
  role             = var.lambda_function_role
  handler          = var.lambda_handler
  runtime          = var.lambda_runtime
  source_code_hash = filebase64sha256(var.lambda_execute_filename)
  environment {
    variables = var.lambda_env_variables
  }
  //  dynamic "environment" {
  //    for_each = local.environment_map
  //    content {
  //      variables = environment.value
  //    }
  //  }
}

output "aws_lambda_function_arn" {
  value = aws_lambda_function.lambda.arn
}

