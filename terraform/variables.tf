locals {
  // Setup some local vars to hold static and dynamic data
  # use caution when making changes to local.common
  # local.common is output to tfstate and used by other configurations
  common = {
    account_id                  = nonsensitive(data.aws_ssm_parameter.account_id.value)
    region                      = nonsensitive(data.aws_ssm_parameter.region.value)
    environment                 = nonsensitive(data.aws_ssm_parameter.environment.value)
    support_email               = nonsensitive(data.aws_ssm_parameter.support_email.value)
    admin_email                 = nonsensitive(data.aws_ssm_parameter.admin_email.value)
    vpc                         = data.terraform_remote_state.infrastructure.outputs.vpc
    terraform_bucket            = data.terraform_remote_state.infrastructure.outputs.s3.terraform
    backup_bucket               = data.terraform_remote_state.infrastructure.outputs.s3.backup
    instance_maintenance_bucket = data.terraform_remote_state.infrastructure.outputs.s3.instance_maintenance
    disk_alert_linux_script     = data.terraform_remote_state.infrastructure.outputs.disk_alert_linux_script
    certificates                = data.terraform_remote_state.infrastructure.outputs.certificates
    app_slug                    = "waze"
    secrets_path                = "../../waze-secrets"
    config_version              = var.config_version
  }
  default_tags = {
    Repository     = "waze"
    Project        = "DP: Waze"
    Team           = "DP: Waze"
    Owner          = "Support Team"
  }
}

variable "fqdn" {
  type = string
}

variable "config_version" {
  type = string
}
