# ── HUB-PROD SUBSCRIPTION ────────────────────────────────────
# Dedicated hub for the Production environment — completely separate from dev and staging hubs.
# Deploy this BEFORE the prod spoke.
#
# Commands:
#   az login
#   az account set --subscription <subscription_id>
#   terraform init  -backend-config="../subscriptions/hub-prod/backend.tfvars"
#   terraform apply -var-file="../subscriptions/hub-prod/values.tfvars" \
#                   -var="vm_admin_password=<secret>"

subscription_id = "00000000-0000-0000-0000-000000000007"   # replace — hub-prod subscription

# ── NAMING ───────────────────────────────────────────────────
# All hub-prod resources: {type}-{org}-hub-{region_short}-prod-{instance}
# Examples: rg-qoc-hub-we-prod-001 / azfw-qoc-hub-we-prod-001 / kv-qoc-hub-we-prod-001
org          = "qoc"
environment  = "prod"
location     = "westeurope"
region_short = "we"
instance     = "001"

# ── HUB NETWORKING ───────────────────────────────────────────
# Prod hub uses 10.30.0.0/16 — no overlap with dev (10.10.x) or staging (10.20.x)
hub_vnet_cidr = "10.30.0.0/16"
hub_subnet_cidrs = {
  firewall    = "10.30.0.0/26"
  gateway     = "10.30.1.0/27"
  bastion     = "10.30.2.0/26"
  app_gateway = "10.30.3.0/24"
  apim        = "10.30.4.0/28"
  management  = "10.30.5.0/24"
}

# ── FEATURE FLAGS ────────────────────────────────────────────
# All services enabled in prod hub
enable_firewall    = true
enable_app_gateway = true
enable_vpn_gateway = false   # flip to true if on-premises connectivity is needed
enable_bastion     = true
enable_apim        = true
enable_jumpbox     = true
enable_agent_vm    = true

# ── HUB SERVICE CONFIGS ──────────────────────────────────────
firewall_sku_tier = "Premium"   # Premium for prod (IDPS, TLS inspection)
acr_sku           = "Premium"

apim_publisher_name  = "My Organisation"
apim_publisher_email = "platform@example.com"
apim_sku_name        = "Premium_1"   # Premium for prod APIM (SLA + multi-region)

jumpbox_vm_size   = "Standard_D4s_v3"
agent_vm_size     = "Standard_D4s_v3"
vm_admin_username = "azureadmin"
# vm_admin_password — pass via -var flag or pipeline secret
# vm_ssh_public_key  — paste contents of ~/.ssh/id_rsa.pub

tags = {
  cost_center = "engineering"
  owner       = "platform-team"
}
