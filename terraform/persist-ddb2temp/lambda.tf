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
  memory_size      = 10240
  environment {
    variables = {
      TEMP_BUCKET = var.temp_bucket.bucket
    }
  }
  depends_on = [data.archive_file.this]
  tags       = local.common_tags
}

# at minute 0/every 20 minutes, every hour, day of the month, month, day of the week and year
# (Min Hr DoM M DoW Y)
# You can't use * in both the Day-of-month and Day-of-week fields. 
# If you use it in one, you must use ? in the other.
variable "data_type_schedules" {
  description = "Map of data types to individual cron schedules"
  type        = map(string)
  default = {
    alerts         = "cron(5/30 * * * ? *)"
    irregularities = "cron(25/30 * * * ? *)"
    jams           = "cron(35/30 * * * ? *)"
  }
}

# One CloudWatch Rule per data_type
resource "aws_cloudwatch_event_rule" "this" {
  for_each = var.data_type_schedules

  name                = "${var.common.app_slug}_${var.module_slug}_${each.key}"
  description         = "Triggers persist Lambda for ${each.key}"
  schedule_expression = each.value
}

# Lambda permission for each rule
resource "aws_lambda_permission" "this" {
  for_each = var.data_type_schedules

  statement_id  = "AllowExecutionFromCloudWatch-${each.key}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.this[each.key].arn
}

# Event Target for each data_type
resource "aws_cloudwatch_event_target" "this" {
  for_each = var.data_type_schedules

  rule      = aws_cloudwatch_event_rule.this[each.key].name
  target_id = "InvokeLambda-${each.key}"
  arn       = aws_lambda_function.this.arn
  input = jsonencode({
    data_type = each.key
  })
}
