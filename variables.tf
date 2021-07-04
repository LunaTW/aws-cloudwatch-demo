variable "sns_name" {
  description = "The name of the SNS topic to create"
  type        = string
  default     = "luna_monitoring_SNS"
}

variable "tags" {
  description = "A mapping of tags"
  type        = map(string)
  default = {
    system  = "Lottery Suggestion System"
    belong  = "Luna"
    version = "1.0"
    slogan  = "Lottery Recommendation BUY BUY BUY"
  }
}

variable "create_sns_topic" {
  description = "Whether to create the SNS topic"
  type        = bool
  default     = true
}

variable "event_rule_schedule" {
  description = "The schedule in minutes the event rule triggers"
  default     = "rate(5 minutes)"
}

variable "aws_sqs_metric" {
  description = "This is a metric from aws"
  default     = "ApproximateNumberOfMessagesVisible"
}

variable "custom_metric_name" {
  description = "This is a custom metric from sqs"
  default     = "luna_test_metric"
}