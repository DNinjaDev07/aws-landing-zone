data "aws_organizations_organization" "aws_org" {}

resource "aws_organizations_organizational_unit" "workloads" {
  name      = "Workloads"
  parent_id = data.aws_organizations_organization.aws_org.roots[0].id
}

resource "aws_organizations_organizational_unit" "sandbox" {
  name      = "Sandbox"
  parent_id = data.aws_organizations_organization.aws_org.roots[0].id
}

resource "aws_organizations_policy" "region_restriction" {
  name        = "scp-region-restriction"
  description = "Deny actions outside approved regions for workload accounts"
  type        = "SERVICE_CONTROL_POLICY"
  content     = file("${path.module}/policies/scp-region-restriction.json")
}

resource "aws_organizations_policy" "deny_root_usage" {
  name        = "scp-deny-root-usage"
  description = "Deny API actions from root user principals"
  type        = "SERVICE_CONTROL_POLICY"
  content     = file("${path.module}/policies/scp-deny-root.json")
}

resource "aws_organizations_policy" "require_encryption" {
  name        = "scp-require-encryption"
  description = "Require encryption for EBS launch volumes and S3 object uploads"
  type        = "SERVICE_CONTROL_POLICY"
  content     = file("${path.module}/policies/scp-require-encryption.json")
}

resource "aws_organizations_policy_attachment" "workloads_region_restriction" {
  policy_id = aws_organizations_policy.region_restriction.id
  target_id = aws_organizations_organizational_unit.workloads.id
}

resource "aws_organizations_policy_attachment" "workloads_deny_root_usage" {
  policy_id = aws_organizations_policy.deny_root_usage.id
  target_id = aws_organizations_organizational_unit.workloads.id
}

resource "aws_organizations_policy_attachment" "workloads_require_encryption" {
  policy_id = aws_organizations_policy.require_encryption.id
  target_id = aws_organizations_organizational_unit.workloads.id
}
