# Remote state lookup for the account-map component (or fallback to static mapping).
#
# When account_map_enabled is true:
#   - Performs remote state lookup to retrieve account mappings from the account-map component
#   - Uses the component's own context (tenant/environment/stage) for the lookup
#
# When account_map_enabled is false:
#   - Bypasses the remote state lookup (bypass = true)
#   - Returns the static account_map variable as defaults instead
#   - Allows the component to function without the account-map dependency
module "account_map" {
  source  = "cloudposse/stack-config/yaml//modules/remote-state"
  version = "1.8.0"

  component = var.account_map_component_name

  context = module.this.context

  # When account_map is disabled, bypass remote state and use the static account_map variable
  bypass   = !var.account_map_enabled
  defaults = var.account_map
}
