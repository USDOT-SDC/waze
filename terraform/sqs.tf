resource "aws_sqs_queue" "deletion" {
  name                       = "waze-ddb-deletion-queue"
  message_retention_seconds  = 86400 # 1 day
  visibility_timeout_seconds = 60    # Adjust based on Lambda runtime
  receive_wait_time_seconds  = 10    # Enables long polling
}
