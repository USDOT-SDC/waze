# module "hello_world" {
#   module_name = "Hello World!"
#   module_slug = "hello-world"
#   source      = "./hello-world"
#   common      = local.common
# }

module "ingest" {
  module_name         = "Ingest"
  module_slug         = "ingest"
  source              = "./ingest"
  common              = local.common
  partner_id          = nonsensitive(data.aws_ssm_parameter.partner_id.value)
  raw_bucket          = aws_s3_bucket.raw
  standardized_bucket = aws_s3_bucket.standardized
}
