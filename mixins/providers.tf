# This mixin replaces the default providers.tf to use profile-based
# authentication and static account mapping instead of the account-map module.
# Use this when deploying with Atmos Auth profiles.
#
# Key differences from the default providers.tf:
# - account_map_enabled defaults to false
# - Removes the root provider block (use provider-root.tf mixin instead)
# - Removes iam_roles_root module (not needed with profile-based auth)

variable "account_map_enabled" {
  type        = bool
  description = <<-EOT
    When true, uses the account-map component to look up account IDs dynamically.
    When false, uses the static account_map variable instead. Set to false when
    using Atmos Auth profiles and static account mappings.
    EOT
  default     = false
}

variable "account_map" {
  type = object({
    full_account_map           = map(string)
    audit_account_account_name = optional(string, "")
    root_account_account_name  = optional(string, "")
  })
  description = <<-EOT
    Static account map used when account_map_enabled is false.
    Provides account name to account ID mapping without requiring the account-map component.
    EOT
  default = {
    full_account_map           = {}
    audit_account_account_name = ""
    root_account_account_name  = ""
  }
}

variable "profile_name" {
  type        = string
  description = "The profile name to use for the default provider"
  default     = "core-root/terraform"
}

provider "aws" {
  region  = var.region
  profile = var.profile_name
}
