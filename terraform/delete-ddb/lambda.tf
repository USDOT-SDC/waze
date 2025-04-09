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
}

resource "aws_lambda_function" "this" {
  function_name                  = "${var.common.app_slug}_${var.module_slug}"
  filename                       = data.archive_file.this.output_path
  source_code_hash               = data.archive_file.this.output_base64sha256
  role                           = aws_iam_role.this.arn
  handler                        = "lambda_function.lambda_handler"
  runtime                        = local.runtime
  timeout                        = 120
  depends_on                     = [data.archive_file.this]
  # reserved_concurrent_executions = 10
  tags                           = local.common_tags
}

resource "aws_lambda_event_source_mapping" "sqs_to_lambda" {
  event_source_arn                   = var.deletion_queue.arn
  function_name                      = aws_lambda_function.this.function_name
  batch_size                         = 25
  maximum_batching_window_in_seconds = 5
  function_response_types            = ["ReportBatchItemFailures"]
  enabled                            = true
}
