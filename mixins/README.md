# AWS Identity Center Mixins

This directory contains mixin files that can be vendored into your `aws-identity-center` (formerly `aws-sso`) component to add additional permission sets.

## What are Mixins?

Mixins are additional Terraform files that extend the base component functionality. They allow you to add custom permission sets without modifying the core component code, making it easier to:
- Keep your components up-to-date with upstream changes
- Share common permission set definitions across teams
- Maintain separation between core and custom functionality

## Available Mixins

### `provider-root.tf`

Provides an `aws.root` provider alias for migration scenarios. Use this mixin when upgrading from v1.x to v2.x if you have existing resources that were created with the root provider.

**Variables:**
- `root_profile_name` - The AWS profile name for the root account (default: `"core-root/terraform"`)

**When to use:**
- Migrating from v1.x where `sso_account_assignments_root` was used
- Terraform shows "Provider configuration not present" errors for orphaned resources

After migration is complete, remove this mixin.

### `v1-variables.tf`

Shared variable definitions required by `policy-TerraformUpdateAccess.tf` and `policy-Identity-role-TeamAccess.tf`. These variables were removed from the main component in v2.0.0. **You must vendor this file alongside either of the v1 policy mixins.**

**Variables:**
- `privileged` - Whether the user has privileged access (default: `false`)
- `tfstate_backend_component_name` - The name of the tfstate-backend component (default: `"tfstate-backend"`)
- `aws_teams_accessible` - List of team names for Identity role access (default: `[]`)
- `overridable_team_permission_set_name_pattern` - Pattern for team permission set names (default: `"Identity%sTeamAccess"`)

### `policy-TerraformUpdateAccess.tf`

Provides a permission set for Terraform state access, allowing users to make changes to Terraform state in S3 and DynamoDB.

**Requires:** `v1-variables.tf`

**Variables** (defined in this file):
- `tfstate_environment_name` - The environment where `tfstate-backend` is provisioned (default: `null`, which disables the permission set)

**Variables** (from `v1-variables.tf`):
- `tfstate_backend_component_name`, `privileged`

**Additional requirement:** This mixin references `module.iam_roles.global_stage_name`. The default `providers.tf` shipped in `src/` uses a dummy module that does not provide this output. You must customize `providers.tf` to use the real `account-map/modules/iam-roles` module.

**Permission Set:**
- `TerraformUpdateAccess` - S3 and DynamoDB access for Terraform state operations

**Stack Configuration Example:**

When using this mixin, configure the terraform state variables in your stack:

```yaml
components:
  terraform:
    aws-sso:
      vars:
        tfstate_environment_name: "usw1"
        tf_access_bucket_arn: !terraform.state tfstate-backend core-usw1-root tfstate_backend_s3_bucket_arn
        tf_access_role_arn: !terraform.state tfstate-backend core-usw1-root tfstate_backend_access_role_arns["acme-core-gbl-root-tfstate"]
```

### `policy-Identity-role-TeamAccess.tf`

Generates permission sets for each team role, allowing users to assume team roles in the Identity account.

**Requires:** `v1-variables.tf`

**Variables** (from `v1-variables.tf`):
- `aws_teams_accessible`, `privileged`, `overridable_team_permission_set_name_pattern`

**Permission Sets:**
- Creates one permission set per team (e.g., `IdentityAdminTeamAccess`, `IdentityTerraformTeamAccess`)
- Each includes `ViewOnlyAccess` policy and role assumption permissions

### `policy-PartnerCentral.tf`

Provides 8 AWS Partner Central permission sets for AWS Partner Network (APN) integration:

- `PartnerCentralFullAccess` - Full access to AWS Partner Central and related services
- `PartnerCentralAccountMgmt` - Manage IAM roles linked to partner users
- `PartnerCentralOpportunityMgmt` - Manage opportunities in AWS Partner Central
- `PartnerCentralSandboxAccess` - Developer testing in the Sandbox catalog
- `PartnerCentralResourceSnapshot` - ResourceSnapshotJob permissions
- `PartnerCentralChannelMgmt` - Manage channel programs and relationships
- `PartnerCentralHandshakeMgmt` - Channel handshake approval management
- `PartnerCentralMarketingMgmt` - Manage marketing activities and campaigns

## Usage

### Option 1: Vendor Mixin via component.yaml

Add the mixin to your component's `component.yaml` file:

```yaml
# components/terraform/aws-sso/component.yaml
apiVersion: atmos/v1
kind: ComponentVendorConfig
spec:
  source:
    uri: github.com/cloudposse-terraform-components/aws-identity-center.git//src?ref={{ .Version }}
    version: 1.0.0
    included_paths:
      - "**/**"
    excluded_paths: []

  # Mixins are pulled and merged into your component directory
  mixins:
    - uri: github.com/cloudposse-terraform-components/aws-identity-center.git//mixins/policy-PartnerCentral.tf?ref={{ .Version }}
      version: 1.0.0
      filename: policy-PartnerCentral.tf
```

Then run:
```bash
atmos vendor pull -c aws-sso
```

### Option 2: Vendor Mixin via vendor.yaml

Alternatively, use a centralized `vendor.yaml` file:

```yaml
# vendor.yaml
apiVersion: atmos/v1
kind: AtmosVendorConfig
spec:
  imports: []
  sources:
    - component: "terraform/aws-sso"
      source: "github.com/cloudposse-terraform-components/aws-identity-center.git//src?ref={{ .Version }}"
      version: "1.0.0"
      targets:
        - "components/terraform/aws-sso"
      included_paths:
        - "**/**"
      excluded_paths: []
      mixins:
        - source: "github.com/cloudposse-terraform-components/aws-identity-center.git//mixins/policy-PartnerCentral.tf?ref={{ .Version }}"
          version: "1.0.0"
          filename: "policy-PartnerCentral.tf"
```

Then run:
```bash
atmos vendor pull
```

### Option 3: Manual Copy

Simply copy the mixin file directly to your component directory:

```bash
cp mixins/policy-PartnerCentral.tf components/terraform/aws-sso/
```

## Activating Vendored Permission Sets

After vendoring the mixin, you need to include the permission sets in your component. Create or update the `additional-permission-sets_override.tf` file:

```hcl
# components/terraform/aws-sso/additional-permission-sets_override.tf
locals {
  # Add custom permission sets.
  # See the README for more details.
  overridable_additional_permission_sets = concat(
    local.partner_central_permission_sets,  # Add this line
    # Add other permission set locals here as needed
    # local.custom_permission_sets,
    # local.security_permission_sets,
  )
}
```

The mixin defines `local.partner_central_permission_sets`, which you concatenate into `local.overridable_additional_permission_sets`. This local variable is merged with the component's base permission sets.

## Pattern for Creating Your Own Mixins

To create additional mixin files:

1. Create a `.tf` file in the mixins directory
2. Define a local variable with your permission sets:

```hcl
locals {
  my_custom_permission_sets = [
    {
      name                                = "MyCustomRole"
      description                         = "Description of the role"
      relay_state                         = ""
      session_duration                    = ""
      tags                                = {}
      inline_policy                       = ""
      policy_attachments                  = ["arn:${local.aws_partition}:iam::aws:policy/CustomPolicy"]
      customer_managed_policy_attachments = []
    },
  ]
}
```

3. Reference it in `additional-permission-sets_override.tf`:

```hcl
locals {
  overridable_additional_permission_sets = concat(
    local.my_custom_permission_sets,
    local.partner_central_permission_sets,
  )
}
```

## References

- [Atmos Vendor Documentation](https://atmos.tools/core-concepts/vendoring)
- [AWS Identity Center Component](https://github.com/cloudposse-terraform-components/aws-identity-center)
- [AWS Partner Central Documentation](https://docs.aws.amazon.com/partner-central/)
