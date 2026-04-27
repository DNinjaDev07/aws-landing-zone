output "config_snapshot_bucket_name" {
  description = "Name of the S3 bucket storing AWS Config snapshots."
  value       = aws_s3_bucket.config_snapshots.id
}

output "compliance_sns_topic_arn" {
  description = "SNS topic ARN for compliance notifications."
  value       = aws_sns_topic.compliance_alerts.arn
}

output "config_recorder_name" {
  description = "Name of the AWS Config configuration recorder."
  value       = aws_config_configuration_recorder.this.name
}

output "config_rule_names" {
  description = "Created AWS Config managed rule names."
  value = [
    aws_config_config_rule.ec2_imdsv2_check.name,
    aws_config_config_rule.incoming_ssh_disabled.name,
  ]
}
