locals {
  runtime_name    = "python"
  runtime_version = "3.13"
  runtime         = "${local.runtime_name}${local.runtime_version}"
  src_path        = "${path.module}/src"
}

data "archive_file" "this" {
  type        = "zip"
  source_dir  = local.src_path
  output_path = "${path.module}/deployment/package.zip"
  excludes = setunion(
    fileset("${path.module}/src/", ".venv/**/*"),
    fileset("${path.module}/src/", "**/__pycache__/**/*"),
    fileset("${path.module}/src/", "**/*.dist-info/**/*"),
    fileset("${path.module}/src/", "**/.mark"),
  )
}

resource "aws_lambda_function" "this" {
  function_name    = "${var.common.app_slug}_${var.module_slug}"
  filename         = data.archive_file.this.output_path
  source_code_hash = data.archive_file.this.output_base64sha256
  role             = aws_iam_role.this.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = local.runtime
  timeout          = 900
  memory_size      = 512
  environment {
    variables = {
      DELETE_QUEUE_URL = var.deletion_queue.id
    }
  }
  depends_on = [data.archive_file.this]
  tags       = local.common_tags
}

