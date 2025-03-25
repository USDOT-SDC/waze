locals {
  runtime_name      = "python"
  runtime_version   = "3.13"
  runtime           = "${local.runtime_name}${local.runtime_version}"
  src_path          = "${var.module_slug}\\src"
  packages_path     = "${local.src_path}\\site-packages"
  last_rotation     = var.common.time.rotating.hours.12
  mark_path         = "${local.packages_path}\\.mark"
}

resource "terraform_data" "pip_install" {
  triggers_replace = {
    # Change whitespace in requirements.txt or delete site packages dir to trigger one time
    requirements = filesha256("${path.module}/requirements.txt")
    # If site packages does not exist, ensures it's built before trying to zip non-existent path
    mark_file_exists = fileexists(local.mark_path)
    # Ensures site packages are rebuilt and upgraded often
    last_rotation = local.last_rotation
  }

  provisioner "local-exec" {
    command = "if exist ${local.src_path}\\python\\ rmdir ${local.src_path}\\python /S /Q"
  }

  provisioner "local-exec" {
    command = "if not exist ${local.packages_path} mkdir ${local.packages_path} & echo ${timestamp()} > ${local.mark_path}"
  }

  provisioner "local-exec" {
    command = "pip install --platform manylinux2014_x86_64 --only-binary=:all: --no-binary=:none: --implementation cp --python-version ${local.runtime_version} --upgrade -t ${local.packages_path} -r ${path.module}\\requirements.txt"
  }
}

data "archive_file" "this" {
  type        = "zip"
  source_dir  = local.src_path
  output_path = "${path.module}/deployment/package.zip"
  excludes    = setunion(
    fileset("${path.module}/src/", ".venv/**/*"),
    fileset("${path.module}/src/", "**/__pycache__/**/*"),
    fileset("${path.module}/src/", "**/*.dist-info/**/*"),
    fileset("${path.module}/src/", "**/.mark"),
  )
  depends_on  = [terraform_data.pip_install]
}

resource "aws_s3_object" "deployment_package" {
  bucket      = var.common.terraform_bucket.bucket
  key         = "waze/terraform/deployment_packages/${var.module_slug}.zip"
  source      = data.archive_file.this.output_path
  source_hash = data.archive_file.this.output_base64sha256
  depends_on  = [data.archive_file.this]
  override_provider {
    default_tags {
      tags = {}
    }
  }
}

resource "aws_lambda_function" "this" {
  function_name = "${var.common.app_slug}_${var.module_slug}"
  # filename         = data.archive_file.this.output_path
  # source_code_hash = data.archive_file.this.output_base64sha256
  s3_bucket         = aws_s3_object.deployment_package.bucket
  s3_key            = aws_s3_object.deployment_package.key
  s3_object_version = aws_s3_object.deployment_package.version_id
  role              = aws_iam_role.this.arn
  handler           = "lambda_function.lambda_handler"
  runtime           = local.runtime
  timeout           = 300 # normal run time is around 250 seconds
  environment {
    variables = {
      RAW_BUCKET      = var.raw_bucket.bucket,
      PARTNER_ID      = var.partner_id,
    }
  }
  # depends_on = [data.archive_file.this]
  depends_on = [aws_s3_object.deployment_package]
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
  name                = "this"
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
