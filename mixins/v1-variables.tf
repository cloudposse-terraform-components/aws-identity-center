# Shared variables required by the v1 mixin policy files:
#   - policy-TerraformUpdateAccess.tf
#   - policy-Identity-role-TeamAccess.tf
#
# These variables were removed from the main component in v2.0.0.
# Vendor this file alongside the policy mixins that need them.
#
# Note: var.privileged is defined in the providers.tf mixin, which is
# required when using v1 policy mixins (they reference module.iam_roles).

variable "aws_teams_accessible" {
  type        = set(string)
  description = <<-EOT
    List of IAM roles (e.g. ["admin", "terraform"]) for which to create permission
    sets that allow the user to assume that role. Named like
    admin -> IdentityAdminTeamAccess
    EOT
  default     = []
}

variable "overridable_team_permission_set_name_pattern" {
  type        = string
  description = "The pattern used to generate the AWS SSO PermissionSet name for each team"
  default     = "Identity%sTeamAccess"
}

variable "tfstate_backend_component_name" {
  type        = string
  description = "The name of the tfstate-backend component"
  default     = "tfstate-backend"
}

variable "tfstate_environment_name" {
  type        = string
  description = "The name of the environment where `tfstate-backend` is provisioned. If not set, the TerraformUpdateAccess permission set will not be created."
  default     = null
}
