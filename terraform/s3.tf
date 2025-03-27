# === Data Lake Ingest Data ===
resource "aws_s3_bucket" "ingest" {
  bucket = "${local.common.s3_bucket_prefix}.waze.ingest"
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "ingest" {
  bucket = aws_s3_bucket.ingest.bucket
  rule {
    bucket_key_enabled = false
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "ingest" {
  bucket = aws_s3_bucket.ingest.id
  versioning_configuration {
    status = "Disabled"
  }
}

resource "aws_s3_bucket_policy" "ingest" {
  bucket = aws_s3_bucket.ingest.id
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
            aws_s3_bucket.ingest.arn,
            "${aws_s3_bucket.ingest.arn}/*"
          ]
        }
      ]
    }
  )
}

# === Data Lake Raw Data ===
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

# === Data Lake Standardized Data ===
resource "aws_s3_bucket" "standardized" {
  bucket = "${local.common.s3_bucket_prefix}.waze.standardized"
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "standardized" {
  bucket = aws_s3_bucket.standardized.bucket
  rule {
    bucket_key_enabled = false
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "standardized" {
  bucket = aws_s3_bucket.standardized.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_policy" "standardized" {
  bucket = aws_s3_bucket.standardized.id
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
            aws_s3_bucket.standardized.arn,
            "${aws_s3_bucket.standardized.arn}/*"
          ]
        }
      ]
    }
  )
}
