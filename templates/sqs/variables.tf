variable "sqs_name" {
  description = "The name of the SQS to create"
  type        = string
}

variable "tags" {
  description = "A mapping of tags"
  type        = map(string)
}