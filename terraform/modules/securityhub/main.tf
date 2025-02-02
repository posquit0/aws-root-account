################
# Security Hub #
################

# Get current region
data "aws_region" "current" {
  provider = aws.root-account
}

# Get the organization management account ID
data "aws_caller_identity" "default" {
  provider = aws.root-account
}

# Get the delegated administrator account ID
data "aws_caller_identity" "delegated-administrator" {
  provider = aws.delegated-administrator
}

####################################
# Security Hub in the root account #
####################################
resource "aws_securityhub_account" "default" {
  provider = aws.root-account
}

# Enable Standard: AWS Foundational Security Best Practices
resource "aws_securityhub_standards_subscription" "default-aws-foundational" {
  provider      = aws.root-account
  standards_arn = "arn:aws:securityhub:${data.aws_region.current.name}::standards/aws-foundational-security-best-practices/v/1.0.0"
  depends_on    = [aws_securityhub_account.default]
}

# Enable Standard: CIS AWS Foundations
resource "aws_securityhub_standards_subscription" "default-cis" {
  provider      = aws.root-account
  standards_arn = "arn:aws:securityhub:::ruleset/cis-aws-foundations-benchmark/v/1.2.0"
  depends_on    = [aws_securityhub_account.default]
}

# Enable Standard: PCI DSS v3.2.1
resource "aws_securityhub_standards_subscription" "default-pci" {
  provider      = aws.root-account
  standards_arn = "arn:aws:securityhub:${data.aws_region.current.name}::standards/pci-dss/v/3.2.1"
  depends_on    = [aws_securityhub_account.default]
}

#######################################################
# Security Hub in the delegated administrator account #
#######################################################
resource "aws_securityhub_account" "delegated-administrator" {
  provider = aws.delegated-administrator
}

# Enable Standard: AWS Foundational Security Best Practices
resource "aws_securityhub_standards_subscription" "delegated-administrator-aws-foundational" {
  provider      = aws.delegated-administrator
  standards_arn = "arn:aws:securityhub:${data.aws_region.current.name}::standards/aws-foundational-security-best-practices/v/1.0.0"
  depends_on    = [aws_securityhub_account.delegated-administrator]
}

# Enable Standard: CIS AWS Foundations
resource "aws_securityhub_standards_subscription" "delegated-administrator-cis" {
  provider      = aws.delegated-administrator
  standards_arn = "arn:aws:securityhub:::ruleset/cis-aws-foundations-benchmark/v/1.2.0"
  depends_on    = [aws_securityhub_account.delegated-administrator]
}

# Enable Standard: PCI DSS v3.2.1
resource "aws_securityhub_standards_subscription" "delegated-administrator-pci" {
  provider      = aws.delegated-administrator
  standards_arn = "arn:aws:securityhub:${data.aws_region.current.name}::standards/pci-dss/v/3.2.1"
  depends_on    = [aws_securityhub_account.delegated-administrator]
}

########################################
# Security Hub delegated administrator #
########################################
resource "aws_securityhub_organization_admin_account" "default" {
  provider         = aws.root-account
  admin_account_id = data.aws_caller_identity.delegated-administrator.account_id

  # Security Hub is required to be enabled in the root and delegated administrator accounts to set
  # a delegated administrator
  depends_on = [
    aws_securityhub_account.default,
    aws_securityhub_account.delegated-administrator
  ]
}

# Enable region aggregation in the delegated administrator account
resource "aws_securityhub_finding_aggregator" "delegated-administrator" {
  for_each = var.aggregation_region == true ? toset(["aggregator"]) : toset([])

  provider = aws.delegated-administrator

  linking_mode = "ALL_REGIONS"
  depends_on = [
    aws_securityhub_organization_admin_account.default
  ]
}

################################
# Security Hub member accounts #
################################
resource "aws_securityhub_member" "delegated-administrator" {
  provider = aws.delegated-administrator

  for_each = (var.enrolled_into_securityhub == {}) ? {
    # You still have to enrol the organization management account into Security Hub as it would have been created before Security Hub is auto-enabled.
    management-account = data.aws_caller_identity.default.account_id
  } : var.enrolled_into_securityhub

  # We want to add these accounts as members within the delegated administrator account
  account_id = each.value
  email      = "placeholder-to-avoid-terraform-drift@example.com"
  invite     = false

  # With AWS Organizations, AWS doesn't rely on the email address provided and doesn't send an invite to a member account,
  # as privilege is inferred by the fact the account is already within Organiations.
  # However, once a relationship is established, the SecurityHub API returns an email address, and sets `invite` to true,
  # so Terraform returns a drift.
  # Therefore, we can ignore_changes on both `email` and `invite`. You still need to provide an email, though, so we use
  # placeholder-to-avoid-terraform-drift@example.com as it's a reserved domain (see: https://www.iana.org/domains/reserved)
  lifecycle {
    ignore_changes = [
      email,
      invite
    ]
  }

  # You need to set the Security Hub organisation administrator before adding members
  depends_on = [aws_securityhub_organization_admin_account.default]
}
