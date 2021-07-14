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

module "luna_lottery_SNS_tracking_lambda" {
  source                  = "./templates/lambda_with_log"
  lambda_function_name    = "luna_lottery_SNS_tracking_lambda"
  lambda_execute_filename = "luna_lottery_SNS_tracking.zip"
  lambda_function_role    = module.luna_lottery_recommendation_role.iam_role_arn
  lambda_handler          = "luna_lottery_SNS_tracking.sns_tracking_log"
  principal               = "sns.amazonaws.com"
  lambda_iam_role_name    = module.luna_lottery_recommendation_role.iam_role_name
  lambda_runtime          = "python3.7"
  lambda_env_variables = {
    nothing = "nothing"
  }
//  lambda_upstream_source_arn = module.luna_lottery_recommendation_topic.aws_sns_topic_arn
}

resource "aws_sns_topic_subscription" "lottery_SNS_trigger_tracking_lambda" {
  topic_arn = module.luna_monitoring_topic.aws_sns_topic_arn
  protocol  = "lambda"
  endpoint  = module.luna_lottery_SNS_tracking_lambda.aws_lambda_function_arn
}

module "auto_lottery_generator_lambda" {
  source                  = "./templates/lambda_with_log"
  lambda_function_name    = "luna_auto_lottery_generator_lambda"
  lambda_execute_filename = "luna_auto_lottery_generator.zip"
  lambda_function_role    = module.luna_lottery_recommendation_role.iam_role_arn
  lambda_handler          = "luna_auto_lottery_generator.lottery_generator"
  principal               = "events.amazonaws.com"
  lambda_iam_role_name    = module.luna_lottery_recommendation_role.iam_role_name
  lambda_runtime          = "python3.7"
  lambda_env_variables = {
    targetARN = module.luna_lottery_recommendation_topic.aws_sns_topic_arn
  }
  lambda_upstream_source_arn = module.luna_cloudEvent_trigger_lottery_recommendation_lambda.cloudwatch_event_rule_arn
}

module "luna_cloudEvent_trigger_lottery_recommendation_lambda" {
  source                                = "./templates/cloudevent"
  aws_cloudwatch_event_rule_description = "Luna's Lottery Recommendation, this event will trigger lottery_recommendation_SNS per 5min"
  aws_cloudwatch_event_rule_name        = "luna_cloudEvent_trigger_lottery_recommendation_lambda"
  cloudevent_trigger_target_arn         = module.auto_lottery_generator_lambda.aws_lambda_function_arn
  target_id                             = "SendToSNS"
  event_rule_schedule                   = var.event_rule_schedule
}

module "luna_cloudEvent_trigger_custom_lambda" {
  source                                = "./templates/cloudevent"
  aws_cloudwatch_event_rule_description = "push custom metrics"
  aws_cloudwatch_event_rule_name        = "luna_cloudEvent_trigger_custom_lambda"
  cloudevent_trigger_target_arn         = module.luna_custom_metric_to_cloudwatch_lambda.aws_lambda_function_arn
  target_id                             = "SendToLambda"
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
  source                  = "./templates/lambda_with_log"
  lambda_function_name    = "luna_custom_metric_to_cloudwatch_alarm"
  lambda_execute_filename = "luna_custom_metric_to_cloudwatch.zip"
  lambda_function_role    = module.luna_lottery_recommendation_role.iam_role_arn
  lambda_handler          = "luna_custom_metric_to_cloudwatch.custom_metric"
  lambda_iam_role_name    = module.luna_lottery_recommendation_role.iam_role_name
  principal               = "events.amazonaws.com"
  lambda_runtime          = "python3.7"
  lambda_env_variables = {
    nothing = "nothing"
  }
  lambda_upstream_source_arn = module.luna_cloudEvent_trigger_custom_lambda.cloudwatch_event_rule_arn
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

module "luna_lottery_fraud_check_alarm" {
  source            = "./templates/cloudwatch_metric"
  alarm_name        = "luna_lottery_fraud_check_alarm"
  alarm_description = "Fake! Fake! Fake!"
  dimensions = {
    fraud_choice = "value_is_ten"
  }
  metric_name   = var.fraud_check_metric_name
  threshold     = 1
  namespace     = "Luna"
  statistic     = "Maximum"
  ok_actions    = [module.luna_monitoring_topic.aws_sns_topic_arn]
  alarm_actions = [module.luna_monitoring_topic.aws_sns_topic_arn]
}

resource "aws_cloudwatch_log_metric_filter" "luna_aws_cloudwatch_log_metric_filter" {
  name           = "luna_aws_cloudwatch_log_metric_filter"
  pattern        = "10"
  log_group_name = module.auto_lottery_generator_lambda.log_group_name

  metric_transformation {
    name      = "luna_fraud_check_metric"
    namespace = "Luna"
    //    dimensions = "fraud_choice"
    value = "1"
  }
}

// https://github.com/pulumi/pulumi/issues/1660   Not support
// https://github.com/hashicorp/terraform-provider-aws/blob/master/aws/resource_aws_sns_topic_subscription.go#L43-L55
// https://github.com/zghafari/tf-sns-email-list
module "luna_monitoring_SNS_send_email_to_admin" {
  source          = "./templates/sns_email_subscription"
  display_name    = "luna_monitoring_SNS_send_email_to_admin"
  email_addresses = var.admin_email
  stack_name      = "lunaSNSSendEmailToAdminStack"
  tags            = var.tags
  topicArn        = module.luna_monitoring_topic.aws_sns_topic_arn
}

module "luna_lottery_generator_SNS_send_lottery_tracking_email" {
  source          = "./templates/sns_email_subscription"
  display_name    = "luna_lottery_generator_SNS_send_lottery_tracking_email"
  email_addresses = var.lottery_tracking_email
  stack_name      = "lunaSNSSendEmailToLotteryTrackingEmail"
  tags            = var.tags
  topicArn        = module.luna_lottery_recommendation_topic.aws_sns_topic_arn
}
