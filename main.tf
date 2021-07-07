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

module "luna_monitoring_topic" {
  source       = "./templates/sns"
  display_name = "luna'S monitoring SNS"
  sns_name     = "luna_monitoring_SNS"
  tags         = var.tags
}

module "luna_lottery_recommendation_topic" {
  source       = "./templates/sns"
  display_name = "luna'S Lottery Recommendation SNS"
  sns_name     = "luna_lottery_recommendation_topic"
  tags         = var.tags
}

module "luna_lottery_recommendation_queue" {
  source                     = "./templates/sqs-with-subscription"
  sqs_name                   = "luna_lottery_recommendation_SQS"
  subscribed_sns_topic_names = [module.luna_lottery_recommendation_topic.aws_sns_topic_arn]
  tags                       = var.tags
}

module "auto_lottery_generator_lambda" {
  source = "./templates/lambda_with_log"
  lambda_function_name = "luna_auto_lottery_generator_lambda"
  lambda_execute_filename = "luna_auto_lottery_generator.zip"
  lambda_function_role = module.luna_lottery_recommendation_role.iam_role_arn
  lambda_handler = "luna_auto_lottery_generator.lottery_generator"
  lambda_iam_role_name = module.luna_lottery_recommendation_role.iam_role_name
  lambda_runtime = "python3.7"
  lambda_env_variables = {
    targetARN = var.targetARN
  }
}

module "luna_cloudEvent_trigger_lottery_recommendation_SNS" {
  source                                = "./templates/cloudevent"
  aws_cloudwatch_event_rule_description = "Luna's Lottery Recommendation, this event will trigger lottery_recommendation_SNS per 5min"
  aws_cloudwatch_event_rule_name        = "luna_cloudEvent_trigger_lottery_recommendation_SNS"
  cloudevent_trigger_target_arn         = module.luna_lottery_recommendation_topic.aws_sns_topic_arn
  target_id                             = "SendToSNS"
  event_rule_schedule                   = var.event_rule_schedule
}

module "luna_lottery_sqs_message_Visible_alarm" {
  source            = "./templates/cloudwatch_metric"
  alarm_name        = "luna_lottery_sqs_message_viable_message_alarm"
  alarm_description = "There are enough referral numbers here, it's time to buy lottery tickets~~"
  dimensions = {
    QueueName = module.luna_lottery_recommendation_queue.sqs_queue_name
  }
  metric_name   = var.aws_sqs_metric
  threshold     = 10 // maximum viable message is 10
  namespace     = "AWS/SQS"
  statistic     = "Maximum"
  ok_actions    = [module.luna_monitoring_topic.aws_sns_topic_arn]
  alarm_actions = [module.luna_monitoring_topic.aws_sns_topic_arn]
}

module "luna_custom_metric_to_cloudwatch_lambda" {
  source                  = "./templates/lambda"
  lambda_function_name    = "luna_custom_metric_to_cloudwatch_alarm"
  lambda_execute_filename = "luna_custom_metric_to_cloudwatch.zip"
  lambda_function_role    = module.luna_lottery_recommendation_role.iam_role_arn
  lambda_handler          = "luna_custom_metric_to_cloudwatch.custom_metric"
  lambda_runtime          = "python3.7"
  lambda_env_variables = {
    nothing = "nothing"
  }
}

module "luna_lottery_sqs_message_Visible_custom_alarm" {
  source            = "./templates/cloudwatch_metric"
  alarm_name        = "luna_lottery_sqs_message_Visible_custom_alarm"
  alarm_description = "There are enough referral numbers here, it's time to buy lottery tickets~~ btw, this is from luna custom metric"
  namespace         = "Luna"
  metric_name       = var.custom_metric_name
  statistic         = "Maximum"
  threshold         = 10 // maximum viable message is 10
  ok_actions        = [module.luna_monitoring_topic.aws_sns_topic_arn]
  alarm_actions     = [module.luna_monitoring_topic.aws_sns_topic_arn]
  dimensions = {
    QueueName = module.luna_lottery_recommendation_queue.sqs_queue_name
  }
}

# https://github.com/pulumi/pulumi/issues/1660   Not support ？？？
//https://registry.terraform.io/modules/QuiNovas/sns-email-subscription/aws/latest?tab=inputs
//module "sns-email-subscription" {
//  source  = "QuiNovas/sns-email-subscription/aws"
//  version = "0.0.3"
//  # insert the 2 required variables here
//  email_address = var.admin_email
//  topic_arn = module.luna_monitoring_topic.aws_sns_topic_arn
//}

//resource "aws_sns_topic_subscription" "luna_sns_send_message_to_email" {
//  endpoint = var.admin_email
//  protocol = "email"
//  topic_arn = module.luna_monitoring_topic.aws_sns_topic_arn
//}


