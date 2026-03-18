module "organization" {
  source = "../../modules/organization"
}

module "iam_baseline" {
  source = "../../modules/iam-baseline"
  providers = {
    aws = aws.workload
  }
  environment = var.environment
  tags        = var.aws_tags
}

module "logging" {
  source          = "../../modules/logging"
  environment     = var.environment
  log_bucket_name = var.cloudtrail_log_bucket_name
  tags            = var.aws_tags
}
