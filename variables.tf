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
