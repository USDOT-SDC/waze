resource "aws_ssm_parameter" "partner_id" {
  name        = "/waze/partner_id"
  description = "DOT's Waze partner ID"
  type        = "String"
  value       = " "
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}
data "aws_ssm_parameter" "partner_id" {
  name = "/waze/partner_id"
  depends_on = [
    aws_ssm_parameter.partner_id
  ]
}
