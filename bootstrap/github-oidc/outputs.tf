output "github_oidc_provider_arn" {
  value = aws_iam_openid_connect_provider.github_oidc_provider.arn
}

output "github_oidc_role_arn" {
  value = aws_iam_role.github_oidc_role.arn
}
