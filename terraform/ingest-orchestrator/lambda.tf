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
  function_name    = "${var.common.app_slug}_${var.module_slug}"
  filename         = data.archive_file.this.output_path
  source_code_hash = data.archive_file.this.output_base64sha256
  role             = aws_iam_role.this.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = local.runtime
  timeout          = 60
  memory_size      = 160 # Recommendation from AWS Compute Optimizer
  environment {
    variables = { INGEST_LAMBDA = var.ingest_lambda.function_name }
  }
  depends_on = [data.archive_file.this]
  tags       = local.common_tags
}

resource "aws_lambda_permission" "this" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.this.arn
}

resource "aws_cloudwatch_event_rule" "this" {
  name                = "${var.common.app_slug}_${var.module_slug}"
  description         = "Triggers the ingest Lambda"
  schedule_expression = "cron(0/2 * * * ? *)"
  # at minute 0/every 5 minutes, every hour, day of the month, month, day of the week and year
  # (Min Hr DoM M DoW Y)
  # You can't use * in both the Day-of-month and Day-of-week fields. 
  # If you use it in one, you must use ? in the other.
}

resource "aws_cloudwatch_event_target" "this" {
  rule      = aws_cloudwatch_event_rule.this.name
  target_id = "InvokeLambda"
  arn       = aws_lambda_function.this.arn
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/lambda/${aws_lambda_function.this.function_name}"
  skip_destroy      = "true"
  retention_in_days = 180
}
