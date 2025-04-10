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
  ddb_table = {
    alerts         = aws_dynamodb_table.ingest["waze_ingest_alerts"],
    irregularities = aws_dynamodb_table.ingest["waze_ingest_irregularities"],
    jams           = aws_dynamodb_table.ingest["waze_ingest_jams"],
  }
}

module "delete_ddb" {
  module_name    = "Delete from DynamoDB"
  module_slug    = "delete_ddb"
  source         = "./delete-ddb"
  common         = local.common
  deletion_queue = aws_sqs_queue.deletion
}

module "persist_ddb2temp" {
  module_name = "Persist from DDB to Temp"
  module_slug = "persist_ddb2temp"
  source      = "./persist-ddb2temp"
  common      = local.common
  ddb_table = {
    alerts         = aws_dynamodb_table.ingest["waze_ingest_alerts"],
    irregularities = aws_dynamodb_table.ingest["waze_ingest_irregularities"],
    jams           = aws_dynamodb_table.ingest["waze_ingest_jams"],
  }
  temp_bucket = aws_s3_bucket.temp
}

module "persist_temp2parquet" {
  module_name                = "Persist from Temp to Parquet"
  module_slug                = "persist_temp2parquet"
  source                     = "./persist-temp2parquet"
  common                     = local.common
  temp_bucket                = aws_s3_bucket.temp
  data_lake_bucket           = aws_s3_bucket.data_lake
  lambda_persist_temp2delete = module.persist_temp2delete.lambda_function
}

module "persist_temp2delete" {
  module_name    = "Persist from Temp to Parquet"
  module_slug    = "persist_temp2delete"
  source         = "./persist-temp2delete"
  common         = local.common
  temp_bucket    = aws_s3_bucket.temp
  deletion_queue = aws_sqs_queue.deletion
}
 
