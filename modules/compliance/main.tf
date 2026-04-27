data "aws_caller_identity" "current" {}

locals {
  resolved_config_snapshot_bucket_name = var.config_snapshot_bucket_name != "" ? var.config_snapshot_bucket_name : lower("${var.environment}-${data.aws_caller_identity.current.account_id}-config-snapshots")
}

resource "aws_s3_bucket" "config_snapshots" {
  bucket = local.resolved_config_snapshot_bucket_name
  tags   = var.tags

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "config_snapshots" {
  bucket = aws_s3_bucket.config_snapshots.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "config_snapshots" {
  bucket = aws_s3_bucket.config_snapshots.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "config_snapshots" {
  bucket = aws_s3_bucket.config_snapshots.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "config_snapshots" {
  bucket = aws_s3_bucket.config_snapshots.id

  rule {
    id     = "config-snapshot-retention"
    status = "Enabled"

    transition {
      days          = var.config_snapshot_transition_days
      storage_class = "STANDARD_IA"
    }

    expiration {
      days = var.config_snapshot_expiration_days
    }

    noncurrent_version_expiration {
      noncurrent_days = var.config_snapshot_transition_days
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

data "aws_iam_policy_document" "config_snapshots_bucket_policy" {
  statement {
    sid = "AWSConfigBucketPermissionsCheck"

    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }

    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.config_snapshots.arn]
  }

  statement {
    sid = "AWSConfigBucketDelivery"

    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }

    actions = ["s3:PutObject"]
    resources = [
      "${aws_s3_bucket.config_snapshots.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/Config/*",
    ]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }
}

resource "aws_s3_bucket_policy" "config_snapshots" {
  bucket = aws_s3_bucket.config_snapshots.id
  policy = data.aws_iam_policy_document.config_snapshots_bucket_policy.json
}

resource "aws_sns_topic" "compliance_alerts" {
  name = "${var.environment}-compliance-alerts"
  tags = var.tags
}

data "aws_iam_policy_document" "compliance_alerts_topic" {
  statement {
    sid     = "AllowConfigPublish"
    effect  = "Allow"
    actions = ["SNS:Publish"]

    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }

    resources = [aws_sns_topic.compliance_alerts.arn]
  }
}

resource "aws_sns_topic_policy" "compliance_alerts" {
  arn    = aws_sns_topic.compliance_alerts.arn
  policy = data.aws_iam_policy_document.compliance_alerts_topic.json
}

resource "aws_sns_topic_subscription" "email_alerts" {
  topic_arn           = aws_sns_topic.compliance_alerts.arn
  protocol            = "email"
  endpoint            = var.notification_email
  filter_policy_scope = "MessageBody"
  filter_policy = jsonencode({
    messageType = ["ComplianceChangeNotification"]
  })
}

resource "aws_config_configuration_recorder" "this" {
  name     = "${var.environment}-config-recorder"
  role_arn = var.config_role_arn

  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}

resource "aws_config_delivery_channel" "this" {
  name           = "${var.environment}-config-delivery-channel"
  s3_bucket_name = aws_s3_bucket.config_snapshots.id
  sns_topic_arn  = aws_sns_topic.compliance_alerts.arn

  snapshot_delivery_properties {
    delivery_frequency = "TwentyFour_Hours"
  }

  depends_on = [aws_s3_bucket_policy.config_snapshots]
}

resource "aws_config_configuration_recorder_status" "this" {
  name       = aws_config_configuration_recorder.this.name
  is_enabled = true

  depends_on = [aws_config_delivery_channel.this]
}

resource "aws_config_config_rule" "ec2_imdsv2_check" {
  name = "${var.environment}-ec2-imdsv2-check"

  source {
    owner             = "AWS"
    source_identifier = "EC2_IMDSV2_CHECK"
  }

  depends_on = [aws_config_configuration_recorder_status.this]
}

resource "aws_config_config_rule" "incoming_ssh_disabled" {
  name = "${var.environment}-incoming-ssh-disabled"

  source {
    owner             = "AWS"
    source_identifier = "INCOMING_SSH_DISABLED"
  }

  depends_on = [aws_config_configuration_recorder_status.this]
}

