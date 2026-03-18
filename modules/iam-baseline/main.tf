data "aws_iam_policy_document" "config_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }

}

resource "aws_iam_role" "aws_config_role" {
  name               = "${var.environment}-${var.config_role_name}"
  assume_role_policy = data.aws_iam_policy_document.config_assume_role.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "aws_config_role_policy" {
  role       = aws_iam_role.aws_config_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWS_ConfigRole"
}
