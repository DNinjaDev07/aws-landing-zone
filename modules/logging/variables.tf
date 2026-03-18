variable "environment" {
  description = "Environment name prefix used for logging resources."
  type        = string
}

variable "trail_name" {
  description = "Name of the CloudTrail trail to create."
  type        = string
  default     = "organization-trail"
}

variable "log_bucket_name" {
  description = "Optional CloudTrail log bucket name override. If empty, a name is derived from environment and account ID."
  type        = string
  default     = ""
}

variable "enable_log_file_validation" {
  description = "Enable CloudTrail log file integrity validation."
  type        = bool
  default     = true
}

variable "is_multi_region_trail" {
  description = "Whether the organization trail is multi-region."
  type        = bool
  default     = true
}

variable "log_transition_days" {
  description = "Number of days before transitioning CloudTrail logs to STANDARD_IA."
  type        = number
  default     = 90
}

variable "log_expiration_days" {
  description = "Number of days before expiring CloudTrail logs."
  type        = number
  default     = 365
}

variable "tags" {
  description = "Tags applied to logging resources."
  type        = map(string)
  default     = {}
}
