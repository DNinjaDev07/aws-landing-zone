variable "environment" {
  description = "Environment name prefix used for compliance resources."
  type        = string
}

variable "config_role_arn" {
  description = "IAM role ARN used by AWS Config recorder."
  type        = string
}

variable "notification_email" {
  description = "Email endpoint for compliance alert notifications."
  type        = string
}

variable "config_snapshot_bucket_name" {
  description = "Optional AWS Config snapshot bucket name override. If empty, a name is derived from environment and account ID."
  type        = string
  default     = ""
}

variable "config_snapshot_transition_days" {
  description = "Number of days before transitioning Config snapshots to STANDARD_IA."
  type        = number
  default     = 90
}

variable "config_snapshot_expiration_days" {
  description = "Number of days before expiring Config snapshots."
  type        = number
  default     = 365
}

variable "tags" {
  description = "Tags applied to compliance resources."
  type        = map(string)
  default     = {}
}
