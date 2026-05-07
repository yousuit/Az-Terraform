# ── HUB-STAGING SUBSCRIPTION ─────────────────────────────────
# Dedicated hub for the Staging environment — completely separate from dev and prod hubs.
# Deploy this BEFORE the staging spoke.
#
# Commands:
#   az login
#   az account set --subscription <subscription_id>
#   terraform init  -backend-config="../subscriptions/hub-staging/backend.tfvars"
#   terraform apply -var-file="../subscriptions/hub-staging/values.tfvars" \
#                   -var="vm_admin_password=<secret>"

subscription_id = "00000000-0000-0000-0000-000000000006"   # replace — hub-staging subscription

# ── NAMING ───────────────────────────────────────────────────
# All hub-staging resources: {type}-{org}-hub-{region_short}-staging-{instance}
# Examples: rg-qoc-hub-we-staging-001 / azfw-qoc-hub-we-staging-001 / kv-qoc-hub-we-staging-001
org          = "qoc"
environment  = "staging"
location     = "westeurope"
region_short = "we"
instance     = "001"

# ── HUB NETWORKING ───────────────────────────────────────────
# Staging hub uses 10.20.0.0/16 — no overlap with dev (10.10.x) or prod (10.30.x)
hub_vnet_cidr = "10.20.0.0/16"
hub_subnet_cidrs = {
  firewall    = "10.20.0.0/26"
  gateway     = "10.20.1.0/27"
  bastion     = "10.20.2.0/26"
  app_gateway = "10.20.3.0/24"
  apim        = "10.20.4.0/28"
  management  = "10.20.5.0/24"
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
acr_sku           = "Standard"

apim_publisher_name  = "My Organisation"
apim_publisher_email = "platform@example.com"
apim_sku_name        = "Developer_1"

jumpbox_vm_size   = "Standard_D2s_v3"
agent_vm_size     = "Standard_D4s_v3"
vm_admin_username = "azureadmin"
# vm_admin_password — pass via -var flag
# vm_ssh_public_key  — paste contents of ~/.ssh/id_rsa.pub

tags = {
  cost_center = "engineering"
  owner       = "dev-team"
}
