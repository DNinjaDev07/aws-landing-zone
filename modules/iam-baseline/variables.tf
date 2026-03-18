variable "environment" {
  description = "Environment name prefix used for IAM baseline resources."
  type        = string
}

variable "config_role_name" {
  description = "Base name for the AWS Config IAM role."
  type        = string
  default     = "AWSConfigRole"
}

variable "tags" {
  description = "Tags applied to IAM baseline resources."
  type        = map(string)
  default     = {}
}
