# List of table names for different data types
variable "ddb_table_names" {
  type    = list(string)
  default = ["waze_ingest_alerts", "waze_ingest_jams", "waze_ingest_irregularities"]
}

# Create a DynamoDB table for each data type
resource "aws_dynamodb_table" "this" {
  for_each     = toset(var.ddb_table_names)
  name         = each.key
  billing_mode = "PAY_PER_REQUEST" # On-demand scaling
  hash_key     = "uuid_hash"

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
