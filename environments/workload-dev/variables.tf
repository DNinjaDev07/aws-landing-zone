variable "aws_region" {
  description = "AWS region for the workload environment."
  type        = string
  default     = "us-east-2"
}

variable "aws_tags" {
  description = "A map of tags to apply to all resources."
  type        = map(string)
  default = {
    "Environment" = "Development"
    "Project"     = "AWS Landing Zone"
    "Owner"       = "SuperStar_DevOps"
  }
}

variable "environment" {
  description = "Environment name for workload resources."
  type        = string
}

variable "workload_account_id" {
  description = "Target workload account ID where aliased provider assumes role."
  type        = string

  validation {
    condition     = can(regex("^\\d{12}$", var.workload_account_id))
    error_message = "workload_account_id must be a 12-digit AWS account ID."
  }
}

variable "workload_bootstrap_role_name" {
  description = "Role name used for initial cross-account provisioning into workload account."
  type        = string
  default     = "OrganizationAccountAccessRole"
}

variable "cloudtrail_log_bucket_name" {
  description = "Optional override for CloudTrail log bucket name in management account."
  type        = string
  default     = ""
}

variable "alert_email" {
  description = "Email address for compliance SNS notifications."
  type        = string
}

variable "config_snapshot_bucket_name" {
  description = "Optional override for AWS Config snapshot bucket name in workload account."
  type        = string
  default     = ""
}
