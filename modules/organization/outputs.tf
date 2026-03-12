output "workload_ou_id" {
  value = aws_organizations_organizational_unit.workloads.id
}

output "sandbox_ou_id" {
  value = aws_organizations_organizational_unit.sandbox.id
}

output "organization_id" {
  value = data.aws_organizations_organization.aws_org.id
}
