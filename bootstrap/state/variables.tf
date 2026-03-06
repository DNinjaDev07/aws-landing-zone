variable "aws_region" {
  description = "AWS Region."
  type        = string
  default     = "us-east-2"
}

variable "aws_tags" {
  description = "A map of tags to apply to all resources."
  type        = map(string)
  default = {
    "Environment" = "Development"
    "Project"     = "AWS Landing Zone"
    "Owner"       = "SuperStart_DevOps"
  }
}

# variable "s3_tf_bucket_name" {
#   description = "S3 Bucket for tf state"
#   default     = "tf_state_bucket"
# }


variable "name_prefix" {
  default = "landing-zone"
  type    = string
}
