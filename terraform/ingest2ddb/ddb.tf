# List of table names for different data types
variable "ddb_table_names" {
  type    = list(string)
  default = ["waze_ingest_alerts", "waze_ingest_jams", "waze_ingest_irregularities"]
}

# Create a DynamoDB table for each data type
resource "aws_dynamodb_table" "this" {
  for_each     = toset(var.ddb_table_names)
  name         = each.key
  # billing_mode = "PROVISIONED"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "uuid_hash"

  attribute {
    name = "uuid_hash"
    type = "S" # String
  }

  attribute {
    name = "utc_partition"
    type = "N" # Number
  }

  global_secondary_index {
    # this block in in lifecycle.ignore_changes
    # comment out 'global_secondary_index' in lifecycle.ignore_changes to force Terraform to apply changes
    name               = "utc_partition_index"
    hash_key           = "utc_partition"
    projection_type    = "INCLUDE"
    non_key_attributes = ["data"]
    read_capacity      = 100
    write_capacity     = 100
  }

  point_in_time_recovery {
    enabled = false
  }

  lifecycle {
    ignore_changes = [
      read_capacity,
      write_capacity,
      global_secondary_index # comment this out to force Terraform to apply changes
    ]
  }

  tags = {
    Name = each.key
  }
}

# # === Autoscaling Values ===
# locals {
#   autoscaling = {
#     alerts = {
#       read = {
#         max_capacity = 500
#         min_capacity = 200
#         target_value = 80
#       }
#       write = {
#         max_capacity = 100
#         min_capacity = 10
#         target_value = 80
#       }
#     }
#     irregularities = {
#       read = {
#         max_capacity = 10
#         min_capacity = 1
#         target_value = 80
#       }
#       write = {
#         max_capacity = 20
#         min_capacity = 2
#         target_value = 80
#       }
#     }
#     jams = {
#       read = {
#         max_capacity = 375
#         min_capacity = 125
#         target_value = 80
#       }
#       write = {
#         max_capacity = 450
#         min_capacity = 10
#         target_value = 80
#       }
#     }
#   }
# }

# # === Alerts Autoscaling ===
# # --- Read ---
# resource "aws_appautoscaling_target" "alerts_read" {
#   max_capacity       = local.autoscaling.alerts.read.max_capacity
#   min_capacity       = local.autoscaling.alerts.read.min_capacity
#   service_namespace  = "dynamodb"
#   scalable_dimension = "dynamodb:table:ReadCapacityUnits"
#   resource_id        = "table/${aws_dynamodb_table.this["waze_ingest_alerts"].name}"
# }

# resource "aws_appautoscaling_policy" "alerts_read" {
#   name               = "waze_ingest_alerts-scaling-policy"
#   policy_type        = "TargetTrackingScaling"
#   service_namespace  = aws_appautoscaling_target.alerts_read.service_namespace
#   scalable_dimension = aws_appautoscaling_target.alerts_read.scalable_dimension
#   resource_id        = aws_appautoscaling_target.alerts_read.resource_id

#   target_tracking_scaling_policy_configuration {
#     predefined_metric_specification {
#       predefined_metric_type = "DynamoDBReadCapacityUtilization"
#     }
#     target_value = local.autoscaling.alerts.read.target_value
#   }
# }

# resource "aws_appautoscaling_target" "alerts_gsi_read" {
#   max_capacity       = local.autoscaling.alerts.read.max_capacity
#   min_capacity       = local.autoscaling.alerts.read.min_capacity
#   service_namespace  = "dynamodb"
#   scalable_dimension = "dynamodb:index:ReadCapacityUnits"
#   resource_id        = "table/${aws_dynamodb_table.this["waze_ingest_alerts"].name}/index/utc_partition_index"
# }

# resource "aws_appautoscaling_policy" "alerts_gsi_read" {
#   name               = "waze_ingest_alerts-utc_partition_index-scaling-policy"
#   policy_type        = "TargetTrackingScaling"
#   service_namespace  = aws_appautoscaling_target.alerts_gsi_read.service_namespace
#   scalable_dimension = aws_appautoscaling_target.alerts_gsi_read.scalable_dimension
#   resource_id        = aws_appautoscaling_target.alerts_gsi_read.resource_id

#   target_tracking_scaling_policy_configuration {
#     predefined_metric_specification {
#       predefined_metric_type = "DynamoDBReadCapacityUtilization"
#     }
#     target_value = local.autoscaling.alerts.read.target_value
#   }
# }

# # --- Write ---
# resource "aws_appautoscaling_target" "alerts_write" {
#   max_capacity       = local.autoscaling.alerts.write.max_capacity
#   min_capacity       = local.autoscaling.alerts.write.min_capacity
#   service_namespace  = "dynamodb"
#   scalable_dimension = "dynamodb:table:WriteCapacityUnits"
#   resource_id        = "table/${aws_dynamodb_table.this["waze_ingest_alerts"].name}"
# }

# resource "aws_appautoscaling_policy" "alerts_write" {
#   name               = "waze_ingest_alerts-scaling-policy"
#   policy_type        = "TargetTrackingScaling"
#   service_namespace  = aws_appautoscaling_target.alerts_write.service_namespace
#   scalable_dimension = aws_appautoscaling_target.alerts_write.scalable_dimension
#   resource_id        = aws_appautoscaling_target.alerts_write.resource_id

#   target_tracking_scaling_policy_configuration {
#     predefined_metric_specification {
#       predefined_metric_type = "DynamoDBWriteCapacityUtilization"
#     }
#     target_value = local.autoscaling.alerts.write.target_value
#   }
# }

# resource "aws_appautoscaling_target" "alerts_gsi_write" {
#   max_capacity       = local.autoscaling.alerts.write.max_capacity
#   min_capacity       = local.autoscaling.alerts.write.min_capacity
#   service_namespace  = "dynamodb"
#   scalable_dimension = "dynamodb:index:WriteCapacityUnits"
#   resource_id        = "table/${aws_dynamodb_table.this["waze_ingest_alerts"].name}/index/utc_partition_index"
# }

# resource "aws_appautoscaling_policy" "alerts_gsi_write" {
#   name               = "waze_ingest_alerts-utc_partition_index-scaling-policy"
#   policy_type        = "TargetTrackingScaling"
#   service_namespace  = aws_appautoscaling_target.alerts_gsi_write.service_namespace
#   scalable_dimension = aws_appautoscaling_target.alerts_gsi_write.scalable_dimension
#   resource_id        = aws_appautoscaling_target.alerts_gsi_write.resource_id

#   target_tracking_scaling_policy_configuration {
#     predefined_metric_specification {
#       predefined_metric_type = "DynamoDBWriteCapacityUtilization"
#     }
#     target_value = local.autoscaling.alerts.write.target_value
#   }
# }


# # === Irregularities Autoscaling ===
# # --- Read ---
# resource "aws_appautoscaling_target" "irregularities_read" {
#   max_capacity       = local.autoscaling.irregularities.read.max_capacity
#   min_capacity       = local.autoscaling.irregularities.read.min_capacity
#   service_namespace  = "dynamodb"
#   scalable_dimension = "dynamodb:table:ReadCapacityUnits"
#   resource_id        = "table/${aws_dynamodb_table.this["waze_ingest_irregularities"].name}"
# }

# resource "aws_appautoscaling_policy" "irregularities_read" {
#   name               = "waze_ingest_irregularities-scaling-policy"
#   policy_type        = "TargetTrackingScaling"
#   service_namespace  = aws_appautoscaling_target.irregularities_read.service_namespace
#   scalable_dimension = aws_appautoscaling_target.irregularities_read.scalable_dimension
#   resource_id        = aws_appautoscaling_target.irregularities_read.resource_id

#   target_tracking_scaling_policy_configuration {
#     predefined_metric_specification {
#       predefined_metric_type = "DynamoDBReadCapacityUtilization"
#     }
#     target_value = local.autoscaling.irregularities.read.target_value
#   }
# }

# resource "aws_appautoscaling_target" "irregularities_gsi_read" {
#   max_capacity       = local.autoscaling.irregularities.read.max_capacity
#   min_capacity       = local.autoscaling.irregularities.read.min_capacity
#   service_namespace  = "dynamodb"
#   scalable_dimension = "dynamodb:index:ReadCapacityUnits"
#   resource_id        = "table/${aws_dynamodb_table.this["waze_ingest_irregularities"].name}/index/utc_partition_index"
# }

# resource "aws_appautoscaling_policy" "irregularities_gsi_read" {
#   name               = "waze_ingest_irregularities-utc_partition_index-scaling-policy"
#   policy_type        = "TargetTrackingScaling"
#   service_namespace  = aws_appautoscaling_target.irregularities_gsi_read.service_namespace
#   scalable_dimension = aws_appautoscaling_target.irregularities_gsi_read.scalable_dimension
#   resource_id        = aws_appautoscaling_target.irregularities_gsi_read.resource_id

#   target_tracking_scaling_policy_configuration {
#     predefined_metric_specification {
#       predefined_metric_type = "DynamoDBReadCapacityUtilization"
#     }
#     target_value = local.autoscaling.alerts.read.target_value
#   }
# }

# # --- Write ---
# resource "aws_appautoscaling_target" "irregularities_write" {
#   max_capacity       = local.autoscaling.irregularities.write.max_capacity
#   min_capacity       = local.autoscaling.irregularities.write.min_capacity
#   service_namespace  = "dynamodb"
#   scalable_dimension = "dynamodb:table:WriteCapacityUnits"
#   resource_id        = "table/${aws_dynamodb_table.this["waze_ingest_irregularities"].name}"
# }

# resource "aws_appautoscaling_policy" "irregularities_write" {
#   name               = "waze_ingest_irregularities-scaling-policy"
#   policy_type        = "TargetTrackingScaling"
#   service_namespace  = aws_appautoscaling_target.irregularities_write.service_namespace
#   scalable_dimension = aws_appautoscaling_target.irregularities_write.scalable_dimension
#   resource_id        = aws_appautoscaling_target.irregularities_write.resource_id

#   target_tracking_scaling_policy_configuration {
#     predefined_metric_specification {
#       predefined_metric_type = "DynamoDBWriteCapacityUtilization"
#     }
#     target_value = local.autoscaling.irregularities.write.target_value
#   }
# }

# resource "aws_appautoscaling_target" "irregularities_gsi_write" {
#   max_capacity       = local.autoscaling.irregularities.write.max_capacity
#   min_capacity       = local.autoscaling.irregularities.write.min_capacity
#   service_namespace  = "dynamodb"
#   scalable_dimension = "dynamodb:index:WriteCapacityUnits"
#   resource_id        = "table/${aws_dynamodb_table.this["waze_ingest_irregularities"].name}/index/utc_partition_index"
# }

# resource "aws_appautoscaling_policy" "irregularities_gsi_write" {
#   name               = "waze_ingest_irregularities-utc_partition_index-scaling-policy"
#   policy_type        = "TargetTrackingScaling"
#   service_namespace  = aws_appautoscaling_target.irregularities_gsi_write.service_namespace
#   scalable_dimension = aws_appautoscaling_target.irregularities_gsi_write.scalable_dimension
#   resource_id        = aws_appautoscaling_target.irregularities_gsi_write.resource_id

#   target_tracking_scaling_policy_configuration {
#     predefined_metric_specification {
#       predefined_metric_type = "DynamoDBWriteCapacityUtilization"
#     }
#     target_value = local.autoscaling.alerts.write.target_value
#   }
# }

# # === Jams Autoscaling ===
# # --- Read ---
# resource "aws_appautoscaling_target" "jams_read" {
#   max_capacity       = local.autoscaling.jams.read.max_capacity
#   min_capacity       = local.autoscaling.jams.read.min_capacity
#   service_namespace  = "dynamodb"
#   scalable_dimension = "dynamodb:table:ReadCapacityUnits"
#   resource_id        = "table/${aws_dynamodb_table.this["waze_ingest_jams"].name}"
# }

# resource "aws_appautoscaling_policy" "jams_read" {
#   name               = "waze_ingest_jams-scaling-policy"
#   policy_type        = "TargetTrackingScaling"
#   service_namespace  = aws_appautoscaling_target.jams_read.service_namespace
#   scalable_dimension = aws_appautoscaling_target.jams_read.scalable_dimension
#   resource_id        = aws_appautoscaling_target.jams_read.resource_id

#   target_tracking_scaling_policy_configuration {
#     predefined_metric_specification {
#       predefined_metric_type = "DynamoDBReadCapacityUtilization"
#     }
#     target_value = local.autoscaling.jams.read.target_value
#   }
# }

# resource "aws_appautoscaling_target" "jams_gsi_read" {
#   max_capacity       = local.autoscaling.jams.read.max_capacity
#   min_capacity       = local.autoscaling.jams.read.min_capacity
#   service_namespace  = "dynamodb"
#   scalable_dimension = "dynamodb:index:ReadCapacityUnits"
#   resource_id        = "table/${aws_dynamodb_table.this["waze_ingest_jams"].name}/index/utc_partition_index"
# }

# resource "aws_appautoscaling_policy" "jams_gsi_read" {
#   name               = "waze_ingest_jams-utc_partition_index-scaling-policy"
#   policy_type        = "TargetTrackingScaling"
#   service_namespace  = aws_appautoscaling_target.jams_gsi_read.service_namespace
#   scalable_dimension = aws_appautoscaling_target.jams_gsi_read.scalable_dimension
#   resource_id        = aws_appautoscaling_target.jams_gsi_read.resource_id

#   target_tracking_scaling_policy_configuration {
#     predefined_metric_specification {
#       predefined_metric_type = "DynamoDBReadCapacityUtilization"
#     }
#     target_value = local.autoscaling.jams.read.target_value
#   }
# }

# # --- Write ---
# resource "aws_appautoscaling_target" "jams_write" {
#   max_capacity       = local.autoscaling.jams.write.max_capacity
#   min_capacity       = local.autoscaling.jams.write.min_capacity
#   service_namespace  = "dynamodb"
#   scalable_dimension = "dynamodb:table:WriteCapacityUnits"
#   resource_id        = "table/${aws_dynamodb_table.this["waze_ingest_jams"].name}"
# }

# resource "aws_appautoscaling_policy" "jams_write" {
#   name               = "waze_ingest_jams-scaling-policy"
#   policy_type        = "TargetTrackingScaling"
#   service_namespace  = aws_appautoscaling_target.jams_write.service_namespace
#   scalable_dimension = aws_appautoscaling_target.jams_write.scalable_dimension
#   resource_id        = aws_appautoscaling_target.jams_write.resource_id

#   target_tracking_scaling_policy_configuration {
#     predefined_metric_specification {
#       predefined_metric_type = "DynamoDBWriteCapacityUtilization"
#     }
#     target_value = local.autoscaling.jams.write.target_value
#   }
# }

# resource "aws_appautoscaling_target" "jams_gsi_write" {
#   max_capacity       = local.autoscaling.jams.write.max_capacity
#   min_capacity       = local.autoscaling.jams.write.min_capacity
#   service_namespace  = "dynamodb"
#   scalable_dimension = "dynamodb:index:WriteCapacityUnits"
#   resource_id        = "table/${aws_dynamodb_table.this["waze_ingest_jams"].name}/index/utc_partition_index"
# }

# resource "aws_appautoscaling_policy" "jams_gsi_write" {
#   name               = "waze_ingest_jams-utc_partition_index-scaling-policy"
#   policy_type        = "TargetTrackingScaling"
#   service_namespace  = aws_appautoscaling_target.jams_gsi_write.service_namespace
#   scalable_dimension = aws_appautoscaling_target.jams_gsi_write.scalable_dimension
#   resource_id        = aws_appautoscaling_target.jams_gsi_write.resource_id

#   target_tracking_scaling_policy_configuration {
#     predefined_metric_specification {
#       predefined_metric_type = "DynamoDBWriteCapacityUtilization"
#     }
#     target_value = local.autoscaling.jams.write.target_value
#   }
# }
