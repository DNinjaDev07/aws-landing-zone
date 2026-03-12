data "aws_caller_identity" "current" {}

locals {
  state_bucket_name = lower("${var.name_prefix}-${data.aws_caller_identity.current.account_id}-tfstate")
}

resource "aws_s3_bucket" "tf_state_bucket" {
  #checkov:skip=CKV2_AWS_62:Event notifications are intentionally not enabled for bootstrap state bucket.
  #checkov:skip=CKV_AWS_144:Cross-region replication is deferred for bootstrap simplicity and cost control.
  #checkov:skip=CKV_AWS_18:Access logging requires a dedicated logging bucket and is deferred in bootstrap phase.
  #checkov:skip=CKV2_AWS_61:Lifecycle policy is intentionally deferred for bootstrap simplicity.
  bucket = local.state_bucket_name
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "tf_state_bucket_versioning" {
  bucket = aws_s3_bucket.tf_state_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "tf_state_bucket_lifecycle" {
  bucket = aws_s3_bucket.tf_state_bucket.id

  rule {
    id     = "noncurrent-version-expiration"
    status = "Enabled"

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}

resource "aws_s3_bucket_public_access_block" "tf_state_bucket_public_access_block" {
  bucket = aws_s3_bucket.tf_state_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

#checkov:skip=CKV_AWS_145:Using AES256 for bootstrap simplicity; KMS-based encryption will be added later.
resource "aws_s3_bucket_server_side_encryption_configuration" "tf_state_bucket_encryption" {
  bucket = aws_s3_bucket.tf_state_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
