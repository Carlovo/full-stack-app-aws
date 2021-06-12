data "aws_iam_policy_document" "this_trust" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["${var.service_name}.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "this" {
  name               = var.role_name
  assume_role_policy = data.aws_iam_policy_document.this_trust.json
}

data "aws_iam_policy_document" "this_permission" {
  dynamic "statement" {
    for_each = var.permission_statements

    content {
      actions   = statement.value["actions"]
      resources = statement.value["resources"]
    }
  }
}

resource "aws_iam_role_policy" "this" {
  role   = aws_iam_role.this.id
  policy = data.aws_iam_policy_document.this_permission.json
}
