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
