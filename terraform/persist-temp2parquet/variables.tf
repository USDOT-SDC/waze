variable "module_name" {}
variable "module_slug" {}
variable "common" {}
variable "temp_bucket" {}
variable "data_lake_bucket" {}
variable "lambda_persist_temp2delete" {}
locals {
  common_tags = {
    "Module Slug" = var.module_slug
  }
}
