# Service-linked roles
resource "aws_iam_service_linked_role" "access-analyzer" {
  aws_service_name = "access-analyzer.amazonaws.com"
}

resource "aws_iam_service_linked_role" "compute-optimizer" {
  aws_service_name = "compute-optimizer.amazonaws.com"
}

resource "aws_iam_service_linked_role" "guardduty" {
  aws_service_name = "guardduty.amazonaws.com"
}

resource "aws_iam_service_linked_role" "organizations" {
  aws_service_name = "organizations.amazonaws.com"
  description      = "Service-linked role used by AWS Organizations to enable integration of other AWS services with Organizations."
}

resource "aws_iam_service_linked_role" "resource-access-manager" {
  aws_service_name = "ram.amazonaws.com"
}

resource "aws_iam_service_linked_role" "securityhub" {
  aws_service_name = "securityhub.amazonaws.com"
  description      = "A service-linked role required for AWS Security Hub to access your resources."
}

resource "aws_iam_service_linked_role" "sso" {
  aws_service_name = "sso.amazonaws.com"
  description      = "Service-linked role used by AWS SSO to manage AWS resources, including IAM roles, policies and SAML IdP on your behalf."
}

resource "aws_iam_service_linked_role" "storage-lens" {
  aws_service_name = "storage-lens.s3.amazonaws.com"
}

resource "aws_iam_service_linked_role" "support" {
  aws_service_name = "support.amazonaws.com"
  description      = "Enables resource access for AWS to provide billing, administrative and support services"
}

resource "aws_iam_service_linked_role" "trustedadvisor" {
  aws_service_name = "trustedadvisor.amazonaws.com"
  description      = "Access for the AWS Trusted Advisor Service to help reduce cost, increase performance, and improve security of your AWS environment."
}

resource "aws_iam_service_linked_role" "trustedadvisor-reporting" {
  aws_service_name = "reporting.trustedadvisor.amazonaws.com"
  description      = "Service Linked Role assumed by Trusted Advisor for multi account reporting."
}

## lambda_basic_execution-test
data "aws_iam_policy_document" "lambda_basic_execution-test-assume-role" {
  version = "2012-10-17"

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_basic_execution-test" {
  name               = "lambda_basic_execution-test"
  assume_role_policy = data.aws_iam_policy_document.lambda_basic_execution-test-assume-role.json
}

## lambda-iam-generate-report-role
data "aws_iam_policy_document" "lambda-iam-generate-report-role-assume-role" {
  version = "2012-10-17"

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda-iam-generate-report-role" {
  name               = "lambda-iam-generate-report-role"
  path               = "/service-role/"
  assume_role_policy = data.aws_iam_policy_document.lambda-iam-generate-report-role-assume-role.json

  tags = {}
}

# SSO Administrator role, assumable by the Modernisation Platform to provide access to AWS accounts via AWS SSO
data "aws_iam_policy_document" "modernisation-platform-sso-administrator-assume-role" {
  version = "2012-10-17"

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${aws_organizations_account.modernisation-platform.id}:root"]
    }
  }
}

resource "aws_iam_role" "modernisation-platform-sso-administrator" {
  name               = "ModernisationPlatformSSOAdministrator"
  assume_role_policy = data.aws_iam_policy_document.modernisation-platform-sso-administrator-assume-role.json
  tags               = local.root_account
}

resource "aws_iam_role_policy_attachment" "sso-administrator" {
  role       = aws_iam_role.modernisation-platform-sso-administrator.name
  policy_arn = "arn:aws:iam::aws:policy/AWSSSOMemberAccountAdministrator"
}

resource "aws_iam_role_policy_attachment" "identity-store-administrator" {
  role       = aws_iam_role.modernisation-platform-sso-administrator.name
  policy_arn = aws_iam_policy.modernisation-platform-sso-administrator.arn
}

# Cost Explorer role, assumable by teams (currently only YJAF) to create cost reports for AWS resources
data "aws_iam_policy_document" "cost-explorer-assume-role" {
  version = "2012-10-17"

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${aws_organizations_account.youth-justice-framework-management.id}:root"]
    }
  }
}

resource "aws_iam_role" "cost-explorer-access" {
  name               = "CostExplorerAccessReadOnly"
  assume_role_policy = data.aws_iam_policy_document.cost-explorer-assume-role.json
  tags               = local.root_account
}

resource "aws_iam_role_policy_attachment" "cost-explorer-access" {
  role       = aws_iam_role.cost-explorer-access.name
  policy_arn = aws_iam_policy.cost-explorer-readonly.arn
}

# Organization list read-only role, assumable by teams (currently only MOJ DSD) to list Organization accounts
data "aws_iam_policy_document" "organization-accounts-assume-role" {
  version = "2012-10-17"

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${aws_organizations_account.moj-digital-services.id}:root"]
    }
  }
}

resource "aws_iam_role" "organization-accounts-access" {
  name               = "AWSOrganizationsListReadOnly"
  assume_role_policy = data.aws_iam_policy_document.organization-accounts-assume-role.json
  tags               = local.root_account
}

resource "aws_iam_role_policy_attachment" "organization-accounts-access" {
  role       = aws_iam_role.organization-accounts-access.name
  policy_arn = aws_iam_policy.organization-accounts-readonly.arn
}
