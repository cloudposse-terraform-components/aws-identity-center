# AWS Identity Center Mixins

This directory contains mixin files that can be vendored into your `aws-identity-center` (formerly `aws-sso`) component to add additional permission sets.

## What are Mixins?

Mixins are additional Terraform files that extend the base component functionality. They allow you to add custom permission sets without modifying the core component code, making it easier to:
- Keep your components up-to-date with upstream changes
- Share common permission set definitions across teams
- Maintain separation between core and custom functionality

## Available Mixins

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
