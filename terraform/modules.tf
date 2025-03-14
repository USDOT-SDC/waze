# Foo Module
# module "foo" {
#   module_name  = "Foo"
#   module_slug  = "foo"
#   source       = "./foo"
#   common       = local.common
#   fqdn         = var.fqdn
# }

module "hello_world" {
  module_name   = "Hello World!"
  module_slug   = "hello-world"
  source        = "./hello-world"
  common        = local.common
}
