resource "aws_cloudwatch_log_group" "default" {
  name = var.log_group_name

  tags = var.tags
}

resource "aws_cloudwatch_log_stream" "default" {
  name           = var.log_stream_name
  log_group_name = aws_cloudwatch_log_group.default.name
}
