output "this_sns_topic_arn" {
  description = "ARN of SNS topic"
  value       = element(concat(aws_sns_topic.luna_monitoring_topic.*.arn, [""]), 0)
}