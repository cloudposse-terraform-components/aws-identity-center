# This file exists to satisfy CI provider-pinning checks.
# When vendored, the main component's versions.tf takes precedence.

terraform {
  required_version = ">= 1.3.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
  }
}
