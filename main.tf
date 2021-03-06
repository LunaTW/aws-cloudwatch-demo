// ****************************** SNS ****************************** //
module "luna_monitoring_topic" {
  source       = "./templates/sns"
  display_name = "luna'S monitoring SNS"
  sns_name     = "luna_monitoring_SNS"
  tags         = var.tags
  kms_master_key_id = "alias/luna-lottery-system-key-alias"
}

module "luna_lottery_recommendation_topic" {
  source       = "./templates/sns"
  display_name = "luna'S Lottery Recommendation SNS"
  sns_name     = "luna_lottery_recommendation_topic"
  tags         = var.tags
  kms_master_key_id = "alias/luna-lottery-system-key-alias"
}

// ****************************** SQS ****************************** //
module "luna_lottery_recommendation_queue" {
  source   = "./templates/sqs-with-subscription"
  sqs_name = "luna_lottery_recommendation_SQS"
  subscribed_sns_topic_names = [
    module.luna_lottery_recommendation_topic.aws_sns_topic_arn]
  tags = var.tags
}

// ****************************** lambda ****************************** //
module "auto_lottery_generator_lambda" {
  source                  = "./templates/lambda_with_log"
  lambda_function_name    = "luna_auto_lottery_generator_lambda"
  lambda_execute_filename = "./lambda/luna_auto_lottery_generator.zip"

  //  filebase64sha256("${path.module}/my-package.zip")
  lambda_function_role = module.luna_lottery_recommendation_role.iam_role_arn
  lambda_handler       = "luna_auto_lottery_generator.lottery_generator"
  principal            = "events.amazonaws.com"
  lambda_iam_role_name = module.luna_lottery_recommendation_role.iam_role_name
  lambda_runtime       = "python3.7"
  source_code_hash     = filebase64sha256("./lambda/luna_auto_lottery_generator.zip")
  lambda_env_variables = {
    targetARN = module.luna_lottery_recommendation_topic.aws_sns_topic_arn
  }
  lambda_upstream_source_arn = module.luna_cloudEvent_trigger_lottery_recommendation_lambda.cloudwatch_event_rule_arn
}

//module "luna_lottery_SNS_tracking_lambda" {
//  source                  = "./templates/lambda_with_log"
//  lambda_function_name    = "luna_lottery_SNS_tracking_lambda"
//  lambda_execute_filename = "./lambda/luna_lottery_SNS_tracking.zip"
//  lambda_function_role    = module.luna_lottery_recommendation_role.iam_role_arn
//  lambda_handler          = "luna_lottery_SNS_tracking.sns_tracking_log"
//  principal               = "sns.amazonaws.com"
//  source_code_hash        = filebase64sha256("./lambda/luna_lottery_SNS_tracking.zip")
//  lambda_iam_role_name    = module.luna_lottery_recommendation_role.iam_role_name
//  lambda_runtime          = "python3.7"
//  lambda_env_variables = {
//    nothing = "nothing"
//  }
//}
//
//resource "aws_sns_topic_subscription" "lottery_SNS_trigger_tracking_lambda" {
//  topic_arn = module.luna_lottery_recommendation_topic.aws_sns_topic_arn
//  protocol  = "lambda"
//  endpoint  = module.luna_lottery_SNS_tracking_lambda.aws_lambda_function_arn
//}

module "luna_vip_lottery_recommendation_monitor_lambda" {
  source                  = "./templates/lambda_with_log_and_dlq"
  lambda_function_name    = "luna_vip_lottery_recommendation_monitor_lambda"
  lambda_execute_filename = "./lambda/luna_vip_lottery_recommendation_monitor.zip"
  lambda_function_role    = module.luna_lottery_recommendation_role.iam_role_arn
  lambda_handler          = "luna_vip_lottery_recommendation_monitor.vip_lottery_recommendation_monitor"
  principal               = "sns.amazonaws.com"
  source_code_hash        = filebase64sha256("./lambda/luna_vip_lottery_recommendation_monitor.zip")
  lambda_iam_role_name    = module.luna_lottery_recommendation_role.iam_role_name
  lambda_runtime          = "python3.7"
  lambda_env_variables = {
    nothing = "nothing"
  }
  tags = var.tags
}

resource "aws_sns_topic_subscription" "lottery_SNS_trigger_tracking_lambda" {
  topic_arn = module.luna_lottery_recommendation_topic.aws_sns_topic_arn
  protocol  = "lambda"
  endpoint  = module.luna_vip_lottery_recommendation_monitor_lambda.aws_lambda_function_arn
}







module "luna_lottery_SQS_tracking_lambda" {
  source                  = "./templates/lambda_with_log"
  lambda_function_name    = "luna_lottery_SQS_tracking_lambda"
  lambda_execute_filename = "./lambda/luna_lottery_SQS_tracking.zip"
  lambda_function_role    = module.luna_lottery_recommendation_role.iam_role_arn
  lambda_handler          = "luna_lottery_SQS_tracking.sqs_tracking_log"
  principal               = "sqs.amazonaws.com"
  lambda_iam_role_name    = module.luna_lottery_recommendation_role.iam_role_name
  lambda_runtime          = "python3.7"
  source_code_hash        = filebase64sha256("./lambda/luna_lottery_SQS_tracking.zip")
  lambda_env_variables = {
    nothing = "nothing"
  }
}

resource "aws_lambda_event_source_mapping" "lottery_SQS_trigger_tracking_lambda" {
  event_source_arn = module.luna_lottery_recommendation_queue.sqs_queue_arn
  function_name    = module.luna_lottery_SQS_tracking_lambda.aws_lambda_function_arn
}

module "luna_custom_metric_to_cloudwatch_lambda" {
  source                  = "./templates/lambda_with_log"
  lambda_function_name    = "luna_custom_metric_to_cloudwatch_alarm"
  lambda_execute_filename = "./lambda/luna_custom_metric_to_cloudwatch.zip"
  lambda_function_role    = module.luna_lottery_recommendation_role.iam_role_arn
  lambda_handler          = "luna_custom_metric_to_cloudwatch.custom_metric"
  lambda_iam_role_name    = module.luna_lottery_recommendation_role.iam_role_name
  principal               = "events.amazonaws.com"
  lambda_runtime          = "python3.7"
  source_code_hash        = filebase64sha256("./lambda/luna_custom_metric_to_cloudwatch.zip")
  lambda_env_variables = {
    nothing = "nothing"
  }
  lambda_upstream_source_arn = module.luna_cloudEvent_trigger_custom_lambda.cloudwatch_event_rule_arn
}

// ****************************** cloudEvent ****************************** //
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

// ****************************** CloudWatch Alarm ****************************** //
module "luna_lottery_sqs_message_Visible_alarm" {
  source            = "./templates/cloudwatch_metric"
  alarm_name        = "luna_lottery_sqs_message_viable_message_alarm"
  alarm_description = "There are enough referral numbers here, it's time to buy lottery tickets~~"
  dimensions = {
    QueueName = module.luna_lottery_recommendation_queue.sqs_queue_name
  }
  metric_name = var.aws_sqs_metric
  threshold   = 10
  // maximum viable message is 10
  namespace = "AWS/SQS"
  statistic = "Maximum"
  ok_actions = [
    module.luna_monitoring_topic.aws_sns_topic_arn]
  alarm_actions = [
    module.luna_monitoring_topic.aws_sns_topic_arn]
}

module "luna_lottery_sqs_message_Visible_custom_alarm" {
  source            = "./templates/cloudwatch_metric"
  alarm_name        = "luna_lottery_sqs_message_Visible_custom_alarm"
  alarm_description = "There are enough referral numbers here, it's time to buy lottery tickets~~ btw, this is from luna custom metric"
  namespace         = "Luna"
  metric_name       = var.custom_metric_name
  statistic         = "Maximum"
  threshold         = 10
  // maximum viable message is 10
  ok_actions = [
    module.luna_monitoring_topic.aws_sns_topic_arn]
  alarm_actions = [
    module.luna_monitoring_topic.aws_sns_topic_arn]
  dimensions = {
    QueueName = module.luna_lottery_recommendation_queue.sqs_queue_name
  }
}

module "luna_lottery_fraud_check_alarm_for_vip_user" {
  source            = "./templates/cloudwatch_metric"
  alarm_name        = "luna_lottery_fraud_check_alarm_for_vip_user"
  alarm_description = "Warning! Warning! Warning! VIP system may be under attack!"
  dimensions = {
    QueueName = module.luna_vip_lottery_recommendation_monitor_lambda.dlq_name
  }
  metric_name = var.aws_sqs_metric
  threshold   = 5
  namespace = "AWS/SQS"
  statistic = "Maximum"
  ok_actions = [
    module.luna_monitoring_topic.aws_sns_topic_arn]
  alarm_actions = [
    module.luna_monitoring_topic.aws_sns_topic_arn]
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

// ****************************** templates ****************************** //
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

// ****************************** templates ****************************** //
resource "aws_kms_key" "luna_kms" {
  description             = "KMS key for lottery system"
  deletion_window_in_days = 7
//  enable_key_rotation = true
  tags = var.tags
//  policy = data.aws_iam_policy_document.cloudwatch_alarm_can_use_this_kms.json
}

//https://aws.amazon.com/cn/premiumsupport/knowledge-center/cloudwatch-receive-sns-for-alarm-trigger/
data "aws_iam_policy_document" "cloudwatch_alarm_can_use_this_kms" {

  statement {
    sid = "Enable IAM User Permissions"
    actions = ["kms:*"]

    effect = "Allow"

    principals {
      type = "AWS"
      identifiers = [var.admin_arn]
    }

    resources = ["*"]
  }

  statement {
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey*"
    ]

    effect = "Allow"

    principals {
      type = "Service"
      identifiers = ["cloudwatch.amazonaws.com"]
    }

    resources = [
      "*"
    ]
  }
}

resource "aws_kms_alias" "luna_kms" {
  name          = "alias/luna-lottery-system-key-alias"
  target_key_id = aws_kms_key.luna_kms.key_id
}

resource "aws_kms_grant" "default" {
  name              = "luna-grant"
  key_id            = aws_kms_key.luna_kms.key_id
  grantee_principal = module.luna_lottery_recommendation_role.iam_role_arn
  operations        = ["Encrypt", "Decrypt", "GenerateDataKey"]
}