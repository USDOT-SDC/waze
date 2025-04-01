# List of table names for different data types
variable "ddb_table_names" {
  type    = list(string)
  default = ["waze_ingest_alerts", "waze_ingest_jams", "waze_ingest_irregularities"]
}

# Create a DynamoDB table for each data type
resource "aws_dynamodb_table" "this" {
  for_each     = toset(var.ddb_table_names)
  name         = each.key
  billing_mode = "PROVISIONED"
  # read_capacity = 0
  hash_key = "uuid_hash"

  attribute {
    name = "uuid_hash"
    type = "S" # String
  }

  point_in_time_recovery {
    enabled = false
  }

  tags = {
    Name = each.key
  }
}

# === Autoscaling Values ===
locals {
  autoscaling = {
    alerts = {
      read = {
        max_capacity = 450
        min_capacity = 90
        target_value = 90
      }
      write = {
        max_capacity = 100
        min_capacity = 5
        target_value = 80
      }
    }
    irregularities = {
      read = {
        max_capacity = 7
        min_capacity = 1
        target_value = 90
      }
      write = {
        max_capacity = 20
        min_capacity = 1
        target_value = 80
      }
    }
    jams = {
      read = {
        max_capacity = 500
        min_capacity = 100
        target_value = 90
      }
      write = {
        max_capacity = 450
        min_capacity = 5
        target_value = 80
      }
    }
  }
}

# === Alerts Autoscaling ===
# --- Read ---
resource "aws_appautoscaling_target" "alerts_read" {
  max_capacity       = local.autoscaling.alerts.read.max_capacity
  min_capacity       = local.autoscaling.alerts.read.min_capacity
  service_namespace  = "dynamodb"
  scalable_dimension = "dynamodb:table:ReadCapacityUnits"
  resource_id        = "table/waze_ingest_alerts"
}

resource "aws_appautoscaling_policy" "alerts_read" {
  name               = "waze_ingest_alerts-scaling-policy"
  policy_type        = "TargetTrackingScaling"
  service_namespace  = aws_appautoscaling_target.alerts_read.service_namespace
  scalable_dimension = aws_appautoscaling_target.alerts_read.scalable_dimension
  resource_id        = aws_appautoscaling_target.alerts_read.resource_id

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "DynamoDBReadCapacityUtilization"
    }
    target_value = local.autoscaling.alerts.read.target_value
  }
}
# --- Write ---
resource "aws_appautoscaling_target" "alerts_write" {
  max_capacity       = local.autoscaling.alerts.write.max_capacity
  min_capacity       = local.autoscaling.alerts.write.min_capacity
  service_namespace  = "dynamodb"
  scalable_dimension = "dynamodb:table:WriteCapacityUnits"
  resource_id        = "table/waze_ingest_alerts"
}

resource "aws_appautoscaling_policy" "alerts_write" {
  name               = "waze_ingest_alerts-scaling-policy"
  policy_type        = "TargetTrackingScaling"
  service_namespace  = aws_appautoscaling_target.alerts_write.service_namespace
  scalable_dimension = aws_appautoscaling_target.alerts_write.scalable_dimension
  resource_id        = aws_appautoscaling_target.alerts_write.resource_id

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "DynamoDBWriteCapacityUtilization"
    }
    target_value = local.autoscaling.alerts.write.target_value
  }
}

# === Irregularities Autoscaling ===
# --- Read ---
resource "aws_appautoscaling_target" "irregularities_read" {
  max_capacity       = local.autoscaling.irregularities.read.max_capacity
  min_capacity       = local.autoscaling.irregularities.read.min_capacity
  service_namespace  = "dynamodb"
  scalable_dimension = "dynamodb:table:ReadCapacityUnits"
  resource_id        = "table/waze_ingest_irregularities"
}

resource "aws_appautoscaling_policy" "irregularities_read" {
  name               = "waze_ingest_irregularities-scaling-policy"
  policy_type        = "TargetTrackingScaling"
  service_namespace  = aws_appautoscaling_target.irregularities_read.service_namespace
  scalable_dimension = aws_appautoscaling_target.irregularities_read.scalable_dimension
  resource_id        = aws_appautoscaling_target.irregularities_read.resource_id

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "DynamoDBReadCapacityUtilization"
    }
    target_value = local.autoscaling.irregularities.read.target_value
  }
}
# --- Write ---
resource "aws_appautoscaling_target" "irregularities_write" {
  max_capacity       = local.autoscaling.irregularities.write.max_capacity
  min_capacity       = local.autoscaling.irregularities.write.min_capacity
  service_namespace  = "dynamodb"
  scalable_dimension = "dynamodb:table:WriteCapacityUnits"
  resource_id        = "table/waze_ingest_irregularities"
}

resource "aws_appautoscaling_policy" "irregularities_write" {
  name               = "waze_ingest_irregularities-scaling-policy"
  policy_type        = "TargetTrackingScaling"
  service_namespace  = aws_appautoscaling_target.irregularities_write.service_namespace
  scalable_dimension = aws_appautoscaling_target.irregularities_write.scalable_dimension
  resource_id        = aws_appautoscaling_target.irregularities_write.resource_id

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "DynamoDBWriteCapacityUtilization"
    }
    target_value = local.autoscaling.irregularities.write.target_value
  }
}

# === Jams Autoscaling ===
# --- Read ---
resource "aws_appautoscaling_target" "jams_read" {
  max_capacity       = local.autoscaling.jams.read.max_capacity
  min_capacity       = local.autoscaling.jams.read.min_capacity
  service_namespace  = "dynamodb"
  scalable_dimension = "dynamodb:table:ReadCapacityUnits"
  resource_id        = "table/waze_ingest_jams"
}

resource "aws_appautoscaling_policy" "jams_read" {
  name               = "waze_ingest_jams-scaling-policy"
  policy_type        = "TargetTrackingScaling"
  service_namespace  = aws_appautoscaling_target.jams_read.service_namespace
  scalable_dimension = aws_appautoscaling_target.jams_read.scalable_dimension
  resource_id        = aws_appautoscaling_target.jams_read.resource_id

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "DynamoDBReadCapacityUtilization"
    }
    target_value = local.autoscaling.jams.read.target_value
  }
}
# --- Write ---
resource "aws_appautoscaling_target" "jams_write" {
  max_capacity       = local.autoscaling.jams.write.max_capacity
  min_capacity       = local.autoscaling.jams.write.min_capacity
  service_namespace  = "dynamodb"
  scalable_dimension = "dynamodb:table:WriteCapacityUnits"
  resource_id        = "table/waze_ingest_jams"
}

resource "aws_appautoscaling_policy" "jams_write" {
  name               = "waze_ingest_jams-scaling-policy"
  policy_type        = "TargetTrackingScaling"
  service_namespace  = aws_appautoscaling_target.jams_write.service_namespace
  scalable_dimension = aws_appautoscaling_target.jams_write.scalable_dimension
  resource_id        = aws_appautoscaling_target.jams_write.resource_id

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "DynamoDBWriteCapacityUtilization"
    }
    target_value = local.autoscaling.jams.write.target_value
  }
}
