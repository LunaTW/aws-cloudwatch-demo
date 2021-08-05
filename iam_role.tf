module "luna_lottery_recommendation_role" {
  source                                 = "./templates/iam"
  iam_role_name                          = "luna_lottery_recommendation_role"
  assume_role_identifiers                = ["lambda.amazonaws.com"]
  additional_custom_policy_name          = "luna_lottery_custom_policy_2"
  additional_custom_policy_document_json = data.aws_iam_policy_document.luna_lottery_custom_policy_document.json
}

data "aws_iam_policy_document" "luna_lottery_custom_policy_document" {

  statement {
    actions   = ["cloudwatch:*"]
    resources = ["*"]
  }
  statement {
    actions   = ["lambda:*"]
    resources = ["*"]
  }
  statement {
    actions = ["logs:CreateLogGroup",
      "logs:CreateLogStream",
    "logs:PutLogEvents"]
    resources = ["arn:aws:logs:*:*:*"]
  }
  statement {
    actions   = ["sqs:*"]
    resources = ["*"]
  }
  statement {
    actions   = ["sns:*"]
    resources = ["*"]
  }
//  statement {
//    actions = [
//      "kms:Decrypt",
//      "kms:GenerateDataKey",
//    ]
//    resources = ["*"]
//  }
  statement {
    actions = ["kms:*"]
    resources = ["*"]
  }
}

