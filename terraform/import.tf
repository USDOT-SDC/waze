# import {
#   to = 
#   id = ""
# }

import {
  to = module.ingest.aws_cloudwatch_log_group.this
  id = "/aws/lambda/waze_ingest"
}

import {
  to = module.ingest_orchestrator.aws_cloudwatch_log_group.this
  id = "/aws/lambda/waze_ingest_orchestrator"
}

import {
  to = module.ingest2ddb.aws_cloudwatch_log_group.this
  id = "/aws/lambda/waze_ingest2ddb"
}
