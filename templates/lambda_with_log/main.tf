resource "aws_lambda_function" "lambda" {
  filename      = var.lambda_execute_filename
  function_name = var.lambda_function_name
  role          = var.lambda_function_role
  handler       = var.lambda_handler
  runtime       = var.lambda_runtime
  depends_on = [aws_iam_role_policy_attachment.lambda_logs,
    aws_cloudwatch_log_group.example,]
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

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = var.lambda_iam_role_name
  policy_arn = aws_iam_policy.lambda_logging.arn
}

# See also the following AWS managed policy: AWSLambdaBasicExecutionRole
resource "aws_iam_policy" "lambda_logging" {
  name        = "lambda_logging"
  path        = "/"
  description = "IAM policy for logging from a lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    }
  ]
}
EOF
}
