variable "module_name" {}
variable "module_slug" {}
variable "common" {}
variable "ingest_lambda" {}
locals {
  common_tags = {
    "Module Slug" = var.module_slug
  }
}
