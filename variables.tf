variable "sns_name" {
  description = "The name of the SNS topic to create"
  type        = string
  default     = "luna_monitoring_SNS"
}

variable "create_sns_topic" {
  description = "Whether to create the SNS topic"
  type        = bool
  default     = true
}

variable "event_rule_schedule" {
  description = "The schedule in minutes the event rule triggers"
  default     = "rate(60 minutes)"
}

variable "evaluation_periods" {
  description = "The number of periods over which data is compared to the specified threshold. ps: trigger it per 5min"
  default     = 1
}

variable "monitoring_period" {
  description = "The number of periods over which data is compared to the specified threshold. ps: trigger it per 5min"
  default     = 300
}

variable "aws_sqs_metric" {
  description = "This is a metric from aws"
  default     = "ApproximateNumberOfMessagesVisible"
}
