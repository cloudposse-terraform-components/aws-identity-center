# This mixin replaces the default providers.tf to enable account-map integration.
# It provides:
#   - Real iam-roles module for dynamic role resolution
#   - Provider with profile/role assumption support
#   - account_map_enabled defaults to true
#
# Vendor this file when your infrastructure uses the account-map component.

variable "account_map_enabled" {
  type        = bool
  description = <<-EOT
    When true, uses the account-map component to look up account IDs dynamically.
    When false, uses the static account_map variable instead.
    EOT
  default     = true
}

variable "account_map" {
  type = object({
    full_account_map              = map(string)
    audit_account_account_name    = optional(string, "")
    root_account_account_name     = optional(string, "")
    identity_account_account_name = optional(string, "")
    aws_partition                 = optional(string, "aws")
    iam_role_arn_templates        = optional(map(string), {})
  })
  description = "Map of account names (tenant-stage format) to account IDs. Used to verify we're targeting the correct AWS account. Optional attributes support component-specific functionality (e.g., audit_account_account_name for cloudtrail, root_account_account_name for aws-sso)."
  default = {
    full_account_map              = {}
    audit_account_account_name    = ""
    root_account_account_name     = ""
    identity_account_account_name = ""
    aws_partition                 = "aws"
    iam_role_arn_templates        = {}
  }
}

variable "privileged" {
  type        = bool
  description = "True if the user running the Terraform command already has access to the Terraform backend"
  default     = false
}

provider "aws" {
  region = var.region

  profile = !var.privileged && module.iam_roles.profiles_enabled ? module.iam_roles.terraform_profile_name : null

  dynamic "assume_role" {
    for_each = !var.privileged && module.iam_roles.profiles_enabled ? [] : (
      var.privileged ? compact([module.iam_roles.org_role_arn]) : compact([module.iam_roles.terraform_role_arn])
    )
    content {
      role_arn = assume_role.value
    }
  }
}

module "iam_roles" {
  source     = "../account-map/modules/iam-roles"
  privileged = var.privileged

  context = module.this.context
}
