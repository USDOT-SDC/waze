resource "aws_iam_role" "this" {
  name = "platform.lambda.${var.common.app_slug}.${var.module_slug}.role"
  assume_role_policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Principal" : {
            "Service" : "lambda.amazonaws.com",
            "AWS" : "arn:aws:iam::${var.common.account_id}:root"
          },
          "Action" : "sts:AssumeRole"
        }
      ]
    }
  )
  tags = local.common_tags
}

resource "aws_iam_role_policy" "this_allow_logs" {
  name = "allow_logs"
  role = aws_iam_role.this.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "logs:CreateLogGroup"
        Resource = aws_cloudwatch_log_group.this.arn
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.this.arn}:log-stream:*"
      }
    ]
  })
}

resource "aws_iam_role_policy" "this_allow_put_s3_raw" {
  name = "allow_put_s3_raw"
  role = aws_iam_role.this.id
  policy = jsonencode(
    {
      Version : "2012-10-17",
      Statement : [
        {
          Effect : "Allow",
          Action : [
            "s3:PutObject",
          ],
          Resource : [
            var.raw_bucket.arn,
            "${var.raw_bucket.arn}/*"
          ]
        }
      ]
    }
  )
}

resource "aws_iam_role_policies_exclusive" "this" {
  role_name = aws_iam_role.this.name
  policy_names = [
    aws_iam_role_policy.this_allow_logs.name,
    aws_iam_role_policy.this_allow_put_s3_raw.name,
  ]
}


# arn:aws:sts::505135622787:assumed-role/platform.lambda.waze.ingest.role/waze_ingest
