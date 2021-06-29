terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.5.0"
    }
  }
}

provider "aws" {
  region                  = "ap-southeast-2"
  shared_credentials_file = "~/.aws/credentials"
  profile                 = "tw-aws-beach"
}

resource "aws_sns_topic" "luna_monitoring_topic" {
  name         = var.sns_name
  display_name = "luna'S monitoring SNS"
  tags = {
    belong   = "Luna"
    function = "Monitoring"
  }
}

resource "aws_sns_topic_policy" "luna_monitoring_topic_policy" {
  arn    = aws_sns_topic.luna_monitoring_topic.arn
  policy = data.aws_iam_policy_document.luna_monitoring_SNS_topic_policy.json
}

data "aws_iam_policy_document" "luna_monitoring_SNS_topic_policy" {
  policy_id = "__default_policy_ID"

  statement {
    actions = [
      "SNS:Subscribe",
      "SNS:SetTopicAttributes",
      "SNS:RemovePermission",
      "SNS:Receive",
      "SNS:Publish",
      "SNS:ListSubscriptionsByTopic",
      "SNS:GetTopicAttributes",
      "SNS:DeleteTopic",
      "SNS:AddPermission",
    ]

    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    resources = [
      aws_sns_topic.luna_monitoring_topic.arn,
    ]

    sid = "__default_statement_ID"
  }
}


resource "aws_sns_topic" "luna_lottery_recommendation_topic" {
  name         = "luna_lottery_recommendation_topic"
  display_name = "luna'S Lottery Recommendation SNS"
  tags = {
    belong   = "Luna"
    function = "Lottery Recommendation"
  }
}

resource "aws_sns_topic_policy" "luna_lottery_recommendation_topic_policy" {
  arn    = aws_sns_topic.luna_lottery_recommendation_topic.arn
  policy = data.aws_iam_policy_document.lottery_recommendation_sns_topic_policy.json
}

data "aws_iam_policy_document" "lottery_recommendation_sns_topic_policy" {
  policy_id = "__default_policy_ID"

  statement {
    actions = [
      "SNS:Subscribe",
      "SNS:SetTopicAttributes",
      "SNS:RemovePermission",
      "SNS:Receive",
      "SNS:Publish",
      "SNS:ListSubscriptionsByTopic",
      "SNS:GetTopicAttributes",
      "SNS:DeleteTopic",
      "SNS:AddPermission",
    ]

    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    resources = [
      aws_sns_topic.luna_lottery_recommendation_topic.arn,
    ]

    sid = "__default_statement_ID"
  }
}

resource "aws_sqs_queue" "luna_lottery_recommendation_queue" {
  name = "luna_lottery_recommendation_SQS"
  tags = {
    belong   = "Luna"
    function = "Lottery Recommendation BUY BUY BUY"
  }
}

resource "aws_sqs_queue_policy" "luna_lottery_recommendation_queue_policy" {
  queue_url = aws_sqs_queue.luna_lottery_recommendation_queue.id
  policy    = data.aws_iam_policy_document.lottery_recommendation_queue_policy.json
}

data "aws_iam_policy_document" "lottery_recommendation_queue_policy" {
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
      aws_sqs_queue.luna_lottery_recommendation_queue.arn,
    ]

    sid = "__default_statement_ID"
  }
}

resource "aws_sns_topic_subscription" "lottery_recommendation" {
  topic_arn = aws_sns_topic.luna_lottery_recommendation_topic.arn
  endpoint  = aws_sqs_queue.luna_lottery_recommendation_queue.arn
  protocol  = "sqs"
}

resource "aws_lambda_function" "luna_auto_lottery_generator" {
  filename      = "luna_auto_lottery_generator.zip"
  function_name = "luna_auto_lottery_generator"
  role          = var.luna_lambda_full_access_iam
  handler       = "luna_auto_lottery_generator.lottery_generator"
  runtime       = "python3.7"
  environment {
    variables = {
      targetARN = var.targetARN
    }
  }
}

#Module      : CLOUDWATCH EVENT TARGET
#Description : Terraform module creates Cloudwatch Event Target on AWS.
resource "aws_cloudwatch_event_target" "cloudwatch_trigger_sns" {
  rule      = aws_cloudwatch_event_rule.cloudwatch_rule.name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.luna_lottery_recommendation_topic.arn
}

#Module      : CLOUDWATCH EVENT
#Description : Terraform module creates Cloudwatch Event on AWS.
resource "aws_cloudwatch_event_rule" "cloudwatch_rule" {
  name                = "luna_cloudEvent_trigger_lottery_recommendation_SNS"
  description         = "Luna's Lottery Recommendation, this event will trigger lottery_recommendation_SNS per 5min"
  schedule_expression = var.event_rule_schedule
}

resource "aws_cloudwatch_metric_alarm" "queue_oldest_message_age_over_1day" {
  alarm_name          = "luna_lottery_recommendation_queue_oldest_message_age_over_1day"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.evaluation_periods
  period              = var.monitoring_period
  metric_name         = var.aws_sqs_metric
  namespace           = "AWS/SQS"
  threshold           = "10"
  alarm_description   = "There are enough referral numbers here, it's time to buy lottery tickets~~"
  treat_missing_data  = "notBreaching"
  statistic           = "Maximum"
  actions_enabled     = "true"
  alarm_actions       = [aws_sns_topic.luna_monitoring_topic.arn]
  ok_actions          = [aws_sns_topic.luna_monitoring_topic.arn]
  dimensions = {
    QueueName = aws_sqs_queue.luna_lottery_recommendation_queue.name
  }
}