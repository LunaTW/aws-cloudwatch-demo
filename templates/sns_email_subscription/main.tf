resource "aws_cloudformation_stack" "sns_email_subscription" {
  name          = var.stack_name
  template_body = data.template_file.cloudformation_sns_email_stack
  tags          = var.tags
}

data "template_file" "cloudformation_sns_email_stack" {
  template = file("${path.module}/email-sns-stack.json.tpl")
  vars = {
    display_name = var.display_name
    subscriptions = join(
      ",",
      formatlist(
        "{ \"Endpoint\": \"%s\", \"Protocol\": \"%s\"  }",
        var.email_addresses,
        var.protocol,
      )
    )
  }
}
