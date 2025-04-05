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

import {
  to = module.ingest2ddb.aws_appautoscaling_target.alerts_gsi_read
  id = "dynamodb/table/waze_ingest_alerts/index/utc_partition_index/dynamodb:index:ReadCapacityUnits"
}
import {
  to = module.ingest2ddb.aws_appautoscaling_target.alerts_gsi_write
  id = "dynamodb/table/waze_ingest_alerts/index/utc_partition_index/dynamodb:index:WriteCapacityUnits"
}
import {
  to = module.ingest2ddb.aws_appautoscaling_target.irregularities_gsi_read
  id = "dynamodb/table/waze_ingest_irregularities/index/utc_partition_index/dynamodb:index:ReadCapacityUnits"
}
import {
  to = module.ingest2ddb.aws_appautoscaling_target.irregularities_gsi_write
  id = "dynamodb/table/waze_ingest_irregularities/index/utc_partition_index/dynamodb:index:WriteCapacityUnits"
}
import {
  to = module.ingest2ddb.aws_appautoscaling_target.jams_gsi_read
  id = "dynamodb/table/waze_ingest_jams/index/utc_partition_index/dynamodb:index:ReadCapacityUnits"
}
import {
  to = module.ingest2ddb.aws_appautoscaling_target.jams_gsi_write
  id = "dynamodb/table/waze_ingest_jams/index/utc_partition_index/dynamodb:index:WriteCapacityUnits"
}



import {
  to = module.ingest2ddb.aws_appautoscaling_policy.alerts_gsi_read
  id = "dynamodb/table/waze_ingest_alerts/index/utc_partition_index/dynamodb:index:ReadCapacityUnits/waze_ingest_alerts-utc_partition_index-scaling-policy"
}

import {
  to = module.ingest2ddb.aws_appautoscaling_policy.alerts_gsi_write
  id = "dynamodb/table/waze_ingest_alerts/index/utc_partition_index/dynamodb:index:WriteCapacityUnits/waze_ingest_alerts-utc_partition_index-scaling-policy"
}

import {
  to = module.ingest2ddb.aws_appautoscaling_policy.irregularities_gsi_read
  id = "dynamodb/table/waze_ingest_irregularities/index/utc_partition_index/dynamodb:index:ReadCapacityUnits/waze_ingest_irregularities-utc_partition_index-scaling-policy"
}

import {
  to = module.ingest2ddb.aws_appautoscaling_policy.irregularities_gsi_write
  id = "dynamodb/table/waze_ingest_irregularities/index/utc_partition_index/dynamodb:index:WriteCapacityUnits/waze_ingest_irregularities-utc_partition_index-scaling-policy"
}

import {
  to = module.ingest2ddb.aws_appautoscaling_policy.jams_gsi_read
  id = "dynamodb/table/waze_ingest_jams/index/utc_partition_index/dynamodb:index:ReadCapacityUnits/waze_ingest_jams-utc_partition_index-scaling-policy"
}

import {
  to = module.ingest2ddb.aws_appautoscaling_policy.jams_gsi_write
  id = "dynamodb/table/waze_ingest_jams/index/utc_partition_index/dynamodb:index:WriteCapacityUnits/waze_ingest_jams-utc_partition_index-scaling-policy"
}

# <service-namespace>/<resource-id>/<scalable-dimension>/<policy-name>