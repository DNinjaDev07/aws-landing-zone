resource "aws_iam_openid_connect_provider" "github_oidc_provider" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com",
  ]
}

resource "aws_iam_role" "github_oidc_role" {
  name = "github-oidc-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github_oidc_provider.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = [
              "repo:DNinjaDev07/aws-landing-zone:ref:refs/heads/main",
              "repo:DNinjaDev07/aws-landing-zone:pull_request",
            ]
          }
        }
      }
    ]
  })
}

#checkov:skip=CKV_AWS_274:AdministratorAccess is intentionally temporary for bootstrap and will be replaced later.
resource "aws_iam_role_policy_attachment" "github_oidc_admin_access" {
  role       = aws_iam_role.github_oidc_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
