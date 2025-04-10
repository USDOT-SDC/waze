variable "module_name" {}
variable "module_slug" {}
variable "common" {}
variable "partner_id" {}
variable "orchestrator_lambda" {}
variable "ddb_table" {}
locals {
  common_tags = {
    "Module Slug" = var.module_slug
  }
}
