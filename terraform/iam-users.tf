locals {
  all_iam_users_and_groups = {
    "AnthonyBishop" = [
      aws_iam_group.aws_organisations_service_admins.name,
      aws_iam_group.billing_full_access.name,
      aws_iam_group.iam_user_change_password.name
    ]
    "CeriBuck" = [
      aws_iam_group.billing_full_access.name,
      aws_iam_group.iam_user_change_password.name
    ]
    "claim-crown-court-defence" = []
    "JakeMulley" = [
      aws_iam_group.admins.name,
      aws_iam_group.aws_organisations_service_admins.name,
      aws_iam_group.billing_full_access.name,
      aws_iam_group.iam_user_change_password.name
    ]
    "JasonBirchall" = [
      aws_iam_group.admins.name,
      aws_iam_group.aws_organisations_service_admins.name,
      aws_iam_group.iam_user_change_password.name
    ]
    "LeahCios" = [
      aws_iam_group.billing_full_access.name,
      aws_iam_group.iam_user_change_password.name
    ]
    "MaxLakanu" = [
      aws_iam_group.billing_full_access.name
    ]
    "ModernisationPlatformOrganisationManagement" = []
    "PaulWyborn" = [
      aws_iam_group.admins.name,
      aws_iam_group.aws_organisations_service_admins.name,
      aws_iam_group.billing_full_access.name,
      aws_iam_group.iam_user_change_password.name
    ]
    "Poornima.Krishnasamy" = [
      aws_iam_group.admins.name,
      aws_iam_group.aws_organisations_service_admins.name
    ]
    "SabluMiah" = [
      aws_iam_group.admins.name,
      aws_iam_group.aws_organisations_service_admins.name,
      aws_iam_group.iam_user_change_password.name
    ]
    "SeanBusby" = [
      aws_iam_group.admins.name,
      aws_iam_group.aws_organisations_service_admins.name,
      aws_iam_group.billing_full_access.name,
      aws_iam_group.iam_user_change_password.name
    ]
    "SidElangovan" = [
      aws_iam_group.admins.name
    ]
    "SteveMarshall" = [
      aws_iam_group.admins.name,
      aws_iam_group.aws_organisations_service_admins.name,
      aws_iam_group.billing_full_access.name,
      aws_iam_group.iam_user_change_password.name
    ]
  }
}

# IAM User
resource "aws_iam_user" "user" {
  for_each = local.all_iam_users_and_groups
  name     = each.key

  # This below is only so Terraform represents what is in the AWS account

  ## In the future...
  ## This should be true for all accounts so we can forcibly delete them even if the have AWS access keys set
  force_destroy = each.key == "ModernisationPlatformOrganisationManagement" ? true : false

  ## and this needs to be updated to tag all accounts with specifics
  tags = each.key == "claim-crown-court-defence" ? {
    Agency = "crimebillingonline"
    Owner  = "claim-crown-court-defence"
  } : {}
}

# IAM User Group Memberships
resource "aws_iam_user_group_membership" "group_memberships" {
  for_each = local.all_iam_users_and_groups
  user     = aws_iam_user.user[each.key].name
  groups   = each.value
}

# IAM User direct policy attachments
# In the future these should be a group policy attachment, rather than directly attached to users

## terraform-organisation-management-policy
resource "aws_iam_user_policy_attachment" "terraform-organisation-management-attachment" {
  user       = aws_iam_user.user["ModernisationPlatformOrganisationManagement"].name
  policy_arn = aws_iam_policy.terraform-organisation-management-policy.arn
}

## aws-readonly-billing-access-policy
resource "aws_iam_user_policy_attachment" "aws-readonly-billing-access-policy" {
  user       = aws_iam_user.user["claim-crown-court-defence"].name
  policy_arn = aws_iam_policy.aws-readonly-billing-access-policy.arn
}
