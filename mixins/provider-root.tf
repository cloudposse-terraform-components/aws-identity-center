# This mixin replaces the root provider in providers.tf to use
# profile-based authentication instead of the account-map module.
# Use this when deploying with Atmos Auth profiles.
#
# When using this mixin, you must also use a providers.tf mixin that
# removes the root provider block and iam_roles_root module.

variable "root_profile_name" {
  type        = string
  description = "The profile name to use for the root account"
  default     = "core-root/terraform"
}

provider "aws" {
  # The AWS provider to use to make changes in the root account
  alias  = "root"
  region = var.region

  profile = var.root_profile_name
}
