resource "aws_sqs_queue" "sqs" {
  name = var.sqs_name
  tags = var.tags
}

resource "aws_sqs_queue_policy" "queue_policy" {
  queue_url = aws_sqs_queue.sqs.id
  policy    = data.aws_iam_policy_document.queue_policy_document.json
}

data "aws_iam_policy_document" "queue_policy_document" {
  policy_id = "__default_policy_ID"

  statement {
    actions = [
      "sqs:SendMessage",
      "sqs:ReceiveMessage"
    ]

    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    resources = [
      aws_sqs_queue.sqs.arn,
    ]

    sid = "__default_statement_ID"
  }
}

output "sqs_queue_arn" {
  description = "ARN of sqs topic"
  value       = aws_sqs_queue.sqs.arn
}

output "sqs_queue_name" {
  description = "Name of aws_sqs_queue"
  value       = aws_sqs_queue.sqs.name
}
