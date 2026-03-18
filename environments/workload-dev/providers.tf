provider "aws" {
  region = var.aws_region
  default_tags {
    tags = var.aws_tags
  }
}

provider "aws" {
  alias  = "workload"
  region = var.aws_region

  assume_role {
    role_arn = "arn:aws:iam::${var.workload_account_id}:role/${var.workload_bootstrap_role_name}"
  }

  default_tags {
    tags = var.aws_tags
  }
}
