# use caution when making changes to outputs
# they are put into the tfstate file and can be used by other Terraform configurations
# output "infrastructure_outputs" {
#   value = data.terraform_remote_state.infrastructure.outputs
# }
# --- Output of the Infrastructure Remote State --- 
# "infrastructure_outputs" = {
#   "auto_start" = {
#     "dynamodb_tables" = {
#       "auto_starts" = {
#         "hash_key" = "instance_id"
#         "name" = "instance_auto_starts"
#       }
#       "maintenance_windows" = {
#         "hash_key" = "maintenance_window_id"
#         "name" = "instance_maintenance_windows"
#       }
#     }
#   }
#   "certificates" = {
#     "external" = {
#       "arn" = "arn:aws:acm:...:...:certificate/..."
#       "domain_name" = "....dot.gov"
#     }
#     "internal" = {
#       "arn" = "arn:aws:acm:...:...:certificate/..."
#       "domain_name" = "....dot.gov"
#     }
#   }
#   "disk_alert_linux_script" = {
#     "bucket" = "....platform.instance-maintenance"
#     "key" = ".../disk-alert-linux.py"
#   }
#   "route53_zone" = {
#     "private" = {
#       "arn" = "arn:aws:route53:::hostedzone/..."
#       "id" = "..."
#     }
#     "public" = {
#       "arn" = "arn:aws:route53:::hostedzone/..."
#       "id" = "..."
#     }
#   }
#   "s3" = {
#     "backup" = {
#       "bucket" = "....platform.backup"
#     }
#     "instance_maintenance" = {
#       "bucket" = "....platform.instance-maintenance"
#     }
#     "terraform" = {
#       "bucket" = "....platform.terraform"
#     }
#   }
#   "vpc" = {
#     "default_security_group" = {
#       "id" = "sg-..."
#     }
#     "id" = "vpc-..."
#     "subnet_five" = {
#       "id" = "subnet-..."
#     }
#     "subnet_four" = {
#       "id" = "subnet-..."
#     }
#     "subnet_researcher" = {
#       "id" = "subnet-..."
#     }
#     "subnet_six" = {
#       "id" = "subnet-..."
#     }
#     "subnet_support" = {
#       "id" = "subnet-..."
#     }
#     "subnet_three" = {
#       "id" = "subnet-..."
#     }
#     "subnets" = [
#       "subnet-...",
#       "subnet-...",
#       "subnet-...",
#       "subnet-...",
#       "subnet-...",
#       "subnet-...",
#     ]
#     "transit_gateway" = {
#       "id" = "tgw-..."
#     }
#   }
# }

# output "foo" {
#   value = "bar"
# }
