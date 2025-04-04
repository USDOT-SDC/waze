variable "module_name" {}
variable "module_slug" {}
variable "common" {}
variable "partner_id" {}
variable "raw_bucket" {}
# variable "standardized_bucket" {}
locals {
  common_tags = {
    "Module Slug" = var.module_slug
  }
}
