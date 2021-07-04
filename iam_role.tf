module "luna_lottery_recommendation_role" {
  source                                 = "./templates/iam"
  iam_role_name                          = "luna_lottery_recommendation_role"
  assume_role_identifiers                = ["lambda.amazonaws.com"]
  additional_custom_policy_name          = "luna_lottery_custom_policy"
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
}

//output "luna_lottery_recommendation_role" {
//  description = "ARN of luna_lottery_recommendation_role"
//  value = module.luna_lottery_recommendation_role.iam_role_arn
//}

