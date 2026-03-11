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
    "Owner"       = "SuperStar_DevOps"
  }
}
