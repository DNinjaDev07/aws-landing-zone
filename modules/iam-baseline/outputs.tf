output "aws_config_role_arn" {
  description = "ARN of the AWS Config service role created in the workload account."
  value       = aws_iam_role.aws_config_role.arn
}

output "aws_config_role_name" {
  description = "Name of the AWS Config service role created in the workload account."
  value       = aws_iam_role.aws_config_role.name
}
