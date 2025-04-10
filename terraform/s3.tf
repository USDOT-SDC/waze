# === Data Lake ===
resource "aws_s3_bucket" "data_lake" {
  bucket = "${local.common.s3_bucket_prefix}.waze.data-lake"
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "data_lake" {
  bucket = aws_s3_bucket.data_lake.bucket
  rule {
    bucket_key_enabled = false
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "data_lake" {
  bucket = aws_s3_bucket.data_lake.id
  versioning_configuration {
    status = "Disabled"
  }
}

resource "aws_s3_bucket_policy" "data_lake" {
  bucket = aws_s3_bucket.data_lake.id
  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Principal" : {
            "AWS" : [
              "arn:aws:iam::${local.common.account_id_other}:role/SDC-Power-User-Role",
              "arn:aws:iam::${local.common.account_id_other}:role/DOT-AppTechAdmin",
            ]
          },
          "Action" : [
            "s3:List*",
            "s3:Get*"
          ],
          "Resource" : [
            aws_s3_bucket.data_lake.arn,
            "${aws_s3_bucket.data_lake.arn}/*"
          ]
        }
      ]
    }
  )
}

# === Temp ===
resource "aws_s3_bucket" "temp" {
  bucket = "${local.common.s3_bucket_prefix}.waze.temp"
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "temp" {
  bucket = aws_s3_bucket.temp.bucket
  rule {
    bucket_key_enabled = false
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "temp" {
  bucket = aws_s3_bucket.temp.id
  versioning_configuration {
    status = "Disabled"
  }
}

resource "aws_s3_bucket_policy" "temp" {
  bucket = aws_s3_bucket.temp.id
  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Principal" : {
            "AWS" : [
              "arn:aws:iam::${local.common.account_id_other}:role/SDC-Power-User-Role",
              "arn:aws:iam::${local.common.account_id_other}:role/DOT-AppTechAdmin",
            ]
          },
          "Action" : [
            "s3:List*",
            "s3:Get*"
          ],
          "Resource" : [
            aws_s3_bucket.temp.arn,
            "${aws_s3_bucket.temp.arn}/*"
          ]
        }
      ]
    }
  )
}

resource "aws_s3_bucket_notification" "temp_to_parquet_trigger" {
  bucket = aws_s3_bucket.temp.bucket

  lambda_function {
    events              = ["s3:ObjectCreated:*"] # Trigger on object creation events
    filter_suffix       = ".json"                # Only trigger for JSON files
    lambda_function_arn = module.persist_temp2parquet.lambda_function.arn
  }

  depends_on = [module.persist_temp2parquet.lambda_permission] # Ensure permission is applied before notification
}

# === Raw Data ===
resource "aws_s3_bucket" "raw" {
  bucket = "${local.common.s3_bucket_prefix}.waze.raw"
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "raw" {
  bucket = aws_s3_bucket.raw.bucket
  rule {
    bucket_key_enabled = false
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "raw" {
  bucket = aws_s3_bucket.raw.id
  versioning_configuration {
    status = "Disabled"
  }
}

resource "aws_s3_bucket_policy" "raw" {
  bucket = aws_s3_bucket.raw.id
  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Principal" : {
            "AWS" : [
              "arn:aws:iam::${local.common.account_id_other}:role/SDC-Power-User-Role",
              "arn:aws:iam::${local.common.account_id_other}:role/DOT-AppTechAdmin",
            ]
          },
          "Action" : [
            "s3:List*",
            "s3:Get*"
          ],
          "Resource" : [
            aws_s3_bucket.raw.arn,
            "${aws_s3_bucket.raw.arn}/*"
          ]
        }
      ]
    }
  )
}
