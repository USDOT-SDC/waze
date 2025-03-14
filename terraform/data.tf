data "aws_ssm_parameter" "account_id" {
  name = "account_id"
}

data "aws_ssm_parameter" "region" {
  name = "region"
}

data "aws_ssm_parameter" "environment" {
  name = "environment"
}

data "aws_ssm_parameter" "support_email" {
  name = "support_email"
}

data "aws_ssm_parameter" "admin_email" {
  name = "admin_email"
}

data "terraform_remote_state" "infrastructure" {
  backend = "s3"
  config = {
    region = "us-east-1"
    bucket = "${nonsensitive(data.aws_ssm_parameter.environment.value)}.sdc.dot.gov.platform.terraform"
    key    = "infrastructure/terraform/terraform.tfstate"
  }
}
