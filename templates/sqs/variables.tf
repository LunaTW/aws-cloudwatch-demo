variable "sqs_name" {
  description = "The name of the SQS to create"
  type        = string
}

variable "tags" {
  description = "A mapping of tags"
  type        = map(string)
}

variable "message_retention_seconds" {
  description = "The number of seconds Amazon SQS retains a message."
  default     = 604800
}
