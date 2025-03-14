locals {
  runtime_name       = "python"
  runtime_version    = "3.13"
  runtime            = "${local.runtime_name}${local.runtime_version}"
  source_dir         = "${var.module_slug}\\src"
  site_packages_dir  = "${local.source_dir}\\python\\lib\\${local.runtime}\\site-packages"
  site_packages_mark = "${local.site_packages_dir}\\.mark"
  exclude_venv       = fileset("${path.module}/src/", ".venv/**/*")
  exclude_pycache    = fileset("${path.module}/src/", "**/__pycache__/**/*")
  exclude_dist_info  = fileset("${path.module}/src/", "**/*.dist-info/**/*")
  excludes = setunion(
    local.exclude_venv,
    local.exclude_pycache,
    local.exclude_dist_info,
    [
      ".gitignore",
    ]
  )
}

resource "terraform_data" "pip_install" {
  #   note: Change whitespace in requirements.txt or delete site packages dir to trigger one time
  triggers_replace = {
    requirements       = filesha256("${path.module}/requirements.txt")
    site_packages_mark = fileexists(local.site_packages_mark)
  }

  provisioner "local-exec" {
    command = "if exist ${local.source_dir}\\python\\ rmdir ${local.source_dir}\\python /S /Q"
  }

  provisioner "local-exec" {
    command = "if not exist ${local.site_packages_dir} mkdir ${local.site_packages_dir} & echo foobar > ${local.site_packages_mark}"
  }

  provisioner "local-exec" {
    command = "pip install --platform manylinux2014_x86_64 --only-binary=:all: --no-binary=:none: --implementation cp --python-version ${local.runtime_version} --upgrade -t ${local.site_packages_dir} -r ${path.module}\\requirements.txt"
  }
}

data "archive_file" "this" {
  type        = "zip"
  source_dir  = local.source_dir
  output_path = "${path.module}/deployment/package.zip"
  excludes    = local.excludes
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
  timeout           = 60
  # environment {
  #   variables = var.foo.environment_variables
  # }
  # depends_on = [data.archive_file.this]
  depends_on = [aws_s3_object.deployment_package]
  tags       = local.common_tags
}
