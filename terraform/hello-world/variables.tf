variable "module_name" {}
variable "module_slug" {}
variable "common" {}
locals {
  common_tags = {
    "Module Slug" = var.module_slug
  }
}
