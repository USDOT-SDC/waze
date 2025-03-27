# List of table names for different data types
variable "ddb_table_names" {
  type    = list(string)
  default = ["waze_ingest_alerts", "waze_ingest_jams", "waze_ingest_irregularities"]
}

# Create a DynamoDB table for each data type
resource "aws_dynamodb_table" "this" {
  for_each        = toset(var.ddb_table_names)
  name            = each.key
  billing_mode    = "PAY_PER_REQUEST"  # On-demand scaling
  hash_key        = "uuid"
  range_key       = "hash"

  attribute {
    name = "uuid"
    type = "S"  # String
  }

  attribute {
    name = "hash"
    type = "S"  # String
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = {
    Name        = each.key
  }
}
