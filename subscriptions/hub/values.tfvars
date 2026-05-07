# ── HUB SUBSCRIPTION ─────────────────────────────────────────
# Used by: hub/ root
# Commands:
#   az login
#   az account set --subscription <subscription_id>
#   terraform init  -backend-config="../subscriptions/hub/backend.tfvars"
#   terraform apply -var-file="../subscriptions/hub/values.tfvars" \
#                   -var="vm_admin_password=<secret>"

subscription_id = "00000000-0000-0000-0000-000000000001"   # replace

# ── NAMING ───────────────────────────────────────────────────
# All hub resources: {type}-{org}-hub-{region_short}-{instance}
# Examples: rg-qoc-hub-we-001 / azfw-qoc-hub-we-001 / kv-qoc-hub-we-001
org          = "qoc"
environment  = "shared"
location     = "westeurope"
region_short = "we"
instance     = "001"

# ── HUB NETWORKING ───────────────────────────────────────────
hub_vnet_cidr = "10.0.0.0/16"
hub_subnet_cidrs = {
  firewall    = "10.0.0.0/26"
  gateway     = "10.0.1.0/27"
  bastion     = "10.0.2.0/26"
  app_gateway = "10.0.3.0/24"
  apim        = "10.0.4.0/28"
  management  = "10.0.5.0/24"
}

# ── FEATURE FLAGS ────────────────────────────────────────────
enable_firewall    = true
enable_app_gateway = true
enable_vpn_gateway = false
enable_bastion     = true
enable_apim        = true
enable_jumpbox     = true
enable_agent_vm    = true

# ── HUB SERVICE CONFIGS ──────────────────────────────────────
firewall_sku_tier = "Standard"
acr_sku           = "Premium"
apim_sku_name     = "Developer_1"

apim_publisher_name  = "My Organisation"
apim_publisher_email = "platform@example.com"

jumpbox_vm_size = "Standard_D2s_v3"
agent_vm_size   = "Standard_D4s_v3"
vm_admin_username = "azureadmin"
# vm_admin_password — pass via -var flag or pipeline secret, never store here
# vm_ssh_public_key  — paste the contents of your ~/.ssh/id_rsa.pub

tags = {
  cost_center = "platform"
  owner       = "platform-team"
}
