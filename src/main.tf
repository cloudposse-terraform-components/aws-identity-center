locals {
  # Used by optional mixin files (e.g. policy-Identity-role-TeamAccess.tf)
  enabled = module.this.enabled # tflint-ignore: terraform_unused_declarations

  # module.account_map.outputs provides values from either remote state (when enabled)
  # or from the static var.account_map defaults (when bypassed)
  account_map = module.account_map.outputs.full_account_map

  account_assignments_groups = flatten([
    for account_key, account in var.account_assignments : [
      for principal_key, principal in account.groups : [
        for permissions_key, permissions in principal.permission_sets :
        {
          account             = local.account_map[account_key]
          permission_set_arn  = module.permission_sets.permission_sets[permissions].arn
          permission_set_name = module.permission_sets.permission_sets[permissions].name
          principal_name      = principal_key
          principal_type      = "GROUP"
        }
      ]
    ] if lookup(account, "groups", null) != null
  ])
  account_assignments_users = flatten([
    for account_key, account in var.account_assignments : [
      for principal_key, principal in account.users : [
        for permissions_key, permissions in principal.permission_sets :
        {
          account             = local.account_map[account_key]
          permission_set_arn  = module.permission_sets.permission_sets[permissions].arn
          permission_set_name = module.permission_sets.permission_sets[permissions].name
          principal_name      = principal_key
          principal_type      = "USER"
        }
      ]
    ] if lookup(account, "users", null) != null
  ])

  account_assignments = concat(local.account_assignments_groups, local.account_assignments_users)

  aws_partition = data.aws_partition.current.partition
}

data "aws_ssoadmin_instances" "this" {}

data "aws_partition" "current" {}

resource "aws_identitystore_group" "manual" {
  for_each = toset(var.groups)

  display_name = each.key
  description  = "Group created with Terraform"

  identity_store_id = tolist(data.aws_ssoadmin_instances.this.identity_store_ids)[0]
}

# Look up IdP-managed groups (synced from Google Workspace, Okta, etc.)
data "aws_identitystore_group" "idp" {
  for_each = toset(var.idp_groups)

  identity_store_id = tolist(data.aws_ssoadmin_instances.this.identity_store_ids)[0]

  alternate_identifier {
    unique_attribute {
      attribute_path  = "DisplayName"
      attribute_value = each.key
    }
  }
}

module "permission_sets" {
  source  = "cloudposse/sso/aws//modules/permission-sets"
  version = "1.2.0"

  permission_sets = concat(
    local.overridable_additional_permission_sets,
    local.administrator_access_permission_set,
    local.billing_administrator_access_permission_set,
    local.billing_read_only_access_permission_set,
    local.dns_administrator_access_permission_set,
    local.poweruser_access_permission_set,
    local.read_only_access_permission_set,
    local.root_access_permission_set,
    local.terraform_plan_access_permission_set,
    local.terraform_apply_access_permission_set,
    local.terraform_state_access_permission_set,
    local.terraform_plan_access_additional_permission_sets,
    local.terraform_apply_access_additional_permission_sets,
    local.terraform_state_access_additional_permission_sets,
  )

  context = module.this.context

  depends_on = [
    aws_identitystore_group.manual
  ]
}

module "sso_account_assignments" {
  source  = "cloudposse/sso/aws//modules/account-assignments"
  version = "1.2.0"

  account_assignments = local.account_assignments
  context             = module.this.context

  depends_on = [
    aws_identitystore_group.manual
  ]
}
