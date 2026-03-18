output "cloudtrail_log_bucket_name" {
  description = "Name of the S3 bucket storing CloudTrail organization logs."
  value       = aws_s3_bucket.cloudtrail_logs.id
}

output "cloudtrail_log_bucket_arn" {
  description = "ARN of the S3 bucket storing CloudTrail organization logs."
  value       = aws_s3_bucket.cloudtrail_logs.arn
}

output "organization_trail_arn" {
  description = "ARN of the organization CloudTrail trail."
  value       = aws_cloudtrail.organization_trail.arn
}

output "organization_trail_name" {
  description = "Name of the organization CloudTrail trail."
  value       = aws_cloudtrail.organization_trail.name
}
