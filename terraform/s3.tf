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
