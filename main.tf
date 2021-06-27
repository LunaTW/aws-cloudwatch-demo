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

resource "aws_sns_topic" "luna_lottery_recommendation_topic" {
  name         = "luna_lottery_recommendation_topic"
  display_name = "luna'S Lottery Recommendation SNS"
  tags = {
    belong   = "Luna"
    function = "Lottery Recommendation"
  }
}

resource "aws_sqs_queue" "luna_lottery_recommendation_queue" {
  name         = "luna_lottery_recommendation_SQS"
  tags = {
    belong   = "Luna"
    function = "Lottery Recommendation BUY BUY BUY"
  }
}

resource "aws_sns_topic_subscription" "lottery_recommendation" {
  topic_arn = aws_sns_topic.luna_lottery_recommendation_topic.arn
  endpoint  = aws_sqs_queue.luna_lottery_recommendation_queue.arn
  protocol  = "sqs"
}

resource "aws_lambda_function" "luna_auto_lottery_generator" {
  filename = "luna_auto_lottery_generator.zip"
  function_name="luna_auto_lottery_generator"
  role="arn:aws:iam::x:role/luna_lambda_full_access_iam"
  handler = "luna_auto_lottery_generator.lottery_generator"
  runtime = "python3.7"
}
