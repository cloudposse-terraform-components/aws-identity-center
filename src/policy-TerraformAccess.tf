# Shared variables for Terraform state backend access
variable "tf_access_bucket_arn" {
  type        = string
  description = "The ARN of the S3 bucket for the Terraform state backend."
  default     = ""
}

variable "tf_access_dynamodb_table_arn" {
  type        = string
  description = "The ARN of the DynamoDB table for the Terraform state backend."
  default     = ""
}

variable "tf_access_role_arn" {
  type        = string
  description = "The ARN of the IAM role for accessing the Terraform state backend."
  default     = ""
}

locals {
  tf_access_enabled = module.this.enabled && var.tf_access_bucket_arn != "" && var.tf_access_role_arn != ""

  # Terraform Plan Access permission set
  terraform_plan_access_permission_set = local.tf_access_enabled ? [{
    name                                = "TerraformPlanAccess",
    description                         = "Allow read-only access to Terraform state for planning",
    relay_state                         = "",
    session_duration                    = var.session_duration,
    tags                                = {},
    inline_policy                       = one(data.aws_iam_policy_document.terraform_plan_access[*].json),
    policy_attachments                  = ["arn:${local.aws_partition}:iam::aws:policy/ReadOnlyAccess"]
    customer_managed_policy_attachments = []
  }] : []

  # Terraform Apply Access permission set
  terraform_apply_access_permission_set = local.tf_access_enabled ? [{
    name                                = "TerraformApplyAccess",
    description                         = "Allow full access to Terraform state and account for applying changes",
    relay_state                         = "",
    session_duration                    = var.session_duration,
    tags                                = {},
    inline_policy                       = one(data.aws_iam_policy_document.terraform_apply_access[*].json),
    policy_attachments                  = ["arn:${local.aws_partition}:iam::aws:policy/AdministratorAccess"]
    customer_managed_policy_attachments = []
  }] : []

  # Terraform State Access permission set
  terraform_state_access_permission_set = local.tf_access_enabled ? [{
    name                                = "TerraformStateAccess",
    description                         = "Allow read/write access to Terraform state backend only",
    relay_state                         = "",
    session_duration                    = var.session_duration,
    tags                                = {},
    inline_policy                       = one(data.aws_iam_policy_document.terraform_state_access[*].json),
    policy_attachments                  = []
    customer_managed_policy_attachments = []
  }] : []
}

# Terraform Plan Access - Read-only state access, read-only account access
data "aws_iam_policy_document" "terraform_plan_access" {
  count = local.tf_access_enabled ? 1 : 0

  # Read-only access to Terraform state S3 bucket
  statement {
    sid    = "TerraformStateBackendS3BucketReadOnly"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetObject",
    ]
    resources = [var.tf_access_bucket_arn, "${var.tf_access_bucket_arn}/*"]
  }

  # Allow assuming the Terraform state backend role (needed to read state)
  statement {
    sid    = "TerraformStateBackendAssumeRole"
    effect = "Allow"
    actions = [
      "sts:AssumeRole",
      "sts:TagSession",
      "sts:SetSourceIdentity",
    ]
    resources = [var.tf_access_role_arn]
  }

  # Allow EC2 DescribeRegions - required by many Terraform modules for region validation
  statement {
    sid    = "EC2DescribeRegions"
    effect = "Allow"
    actions = [
      "ec2:DescribeRegions",
    ]
    resources = ["*"]
  }
}

# Terraform Apply Access - Read/write state access, admin account access
data "aws_iam_policy_document" "terraform_apply_access" {
  count = local.tf_access_enabled ? 1 : 0

  statement {
    sid    = "TerraformStateBackendS3Bucket"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetObject",
      "s3:PutObject",
    ]
    resources = [var.tf_access_bucket_arn, "${var.tf_access_bucket_arn}/*"]
  }

  # Only add the DynamoDB table statement if the DynamoDB table ARN is set.
  # You may not have created a DynamoDB table if you're using S3 state locking
  dynamic "statement" {
    for_each = (local.tf_access_enabled && var.tf_access_dynamodb_table_arn != "") ? [1] : []

    content {
      sid       = "TerraformStateBackendDynamoDbTable"
      effect    = "Allow"
      actions   = ["dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:DeleteItem"]
      resources = [var.tf_access_dynamodb_table_arn]
    }
  }

  # Allow assuming the Terraform state backend role
  statement {
    sid    = "TerraformStateBackendAssumeRole"
    effect = "Allow"
    actions = [
      "sts:AssumeRole",
      "sts:TagSession",
      "sts:SetSourceIdentity",
    ]
    resources = [var.tf_access_role_arn]
  }

  # Allow EC2 DescribeRegions - required by many Terraform modules for region validation
  statement {
    sid    = "EC2DescribeRegions"
    effect = "Allow"
    actions = [
      "ec2:DescribeRegions",
    ]
    resources = ["*"]
  }
}

# Terraform State Access - Read/write state access only (no account permissions)
data "aws_iam_policy_document" "terraform_state_access" {
  count = local.tf_access_enabled ? 1 : 0

  # Read/write access to Terraform state S3 bucket
  statement {
    sid    = "TerraformStateBackendS3Bucket"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
    ]
    resources = [var.tf_access_bucket_arn, "${var.tf_access_bucket_arn}/*"]
  }

  # DynamoDB table access for state locking (if configured)
  dynamic "statement" {
    for_each = (local.tf_access_enabled && var.tf_access_dynamodb_table_arn != "") ? [1] : []

    content {
      sid       = "TerraformStateBackendDynamoDbTable"
      effect    = "Allow"
      actions   = ["dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:DeleteItem"]
      resources = [var.tf_access_dynamodb_table_arn]
    }
  }

  # Allow assuming the Terraform state backend role
  statement {
    sid    = "TerraformStateBackendAssumeRole"
    effect = "Allow"
    actions = [
      "sts:AssumeRole",
      "sts:TagSession",
      "sts:SetSourceIdentity",
    ]
    resources = [var.tf_access_role_arn]
  }
}
