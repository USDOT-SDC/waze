variable "module_name" {}
variable "module_slug" {}
variable "common" {}
variable "ddb_table" {}
variable "temp_bucket" {}
locals {
  common_tags = {
    "Module Slug" = var.module_slug
  }
}
