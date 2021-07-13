variable "stack_name" {}

variable "tags" {}

variable "display_name" {}

variable "email_addresses" {
  type        = list(string)
  description = "Email address to send notifications to"
}

variable "protocol" {
  default     = "email"
  description = "SNS Protocol to use. email or email-json"
  type        = string
}