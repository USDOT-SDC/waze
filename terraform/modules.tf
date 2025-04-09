# module "hello_world" {
#   module_name = "Hello World!"
#   module_slug = "hello-world"
#   source      = "./hello-world"
#   common      = local.common
# }

module "ingest" {
  module_name = "Ingest"
  module_slug = "ingest"
  source      = "./ingest"
  common      = local.common
  partner_id  = nonsensitive(data.aws_ssm_parameter.partner_id.value)
  raw_bucket  = aws_s3_bucket.raw
}

module "ingest_orchestrator" {
  module_name   = "Ingest Orchestrator"
  module_slug   = "ingest_orchestrator"
  source        = "./ingest-orchestrator"
  common        = local.common
  ingest_lambda = module.ingest2ddb.lambda
}

module "ingest2ddb" {
  module_name         = "Ingest to DDB"
  module_slug         = "ingest2ddb"
  source              = "./ingest2ddb"
  common              = local.common
  partner_id          = nonsensitive(data.aws_ssm_parameter.partner_id.value)
  orchestrator_lambda = module.ingest_orchestrator.lambda
}

module "delete_ddb" {
  module_name    = "Delete from DynamoDB"
  module_slug    = "delete_ddb"
  source         = "./delete-ddb"
  common         = local.common
  deletion_queue = aws_sqs_queue.deletion
}
