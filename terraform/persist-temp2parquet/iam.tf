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
  policy = jsonencode(
    {
      Version : "2012-10-17",
      Statement : [
        {
          Effect : "Allow",
          Action : [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents",
            "logs:PutMetricFilter",
            "logs:PutRetentionPolicy"
          ],
          Resource : "*"
        }
      ]
    }
  )
}

resource "aws_iam_role_policy" "this_allow_s3" {
  name = "allow_s3"
  role = aws_iam_role.this.id
  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Action" : "s3:GetObject",
          "Resource" : [
            "${var.temp_bucket.arn}/*"
          ]
        },
        {
          "Effect" : "Allow",
          "Action" : "s3:PutObject",
          "Resource" : [
            "${var.data_lake_bucket.arn}/*"
          ]
        }
      ]
    }
  )
}

resource "aws_iam_role_policy" "this_allow_invoke_delete" {
  name = "allow_invoke_delete"
  role = aws_iam_role.this.id
  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Action" : "lambda:InvokeFunction",
          "Resource" : var.lambda_persist_temp2delete.arn
        }
      ]
    }
  )
}

resource "aws_iam_role_policies_exclusive" "this" {
  role_name = aws_iam_role.this.name
  policy_names = [
    aws_iam_role_policy.this_allow_logs.name,
    aws_iam_role_policy.this_allow_s3.name,
    aws_iam_role_policy.this_allow_invoke_delete.name,
  ]
}
