# ── IDENTITY ──────────────────────────────────────────────────
variable "subscription_id" {
  description = "Hub Azure subscription ID"
  type        = string
}

# ── NAMING ────────────────────────────────────────────────────
variable "org" {
  description = "Short organisation/project code used in every resource name (e.g. qoc)"
  type        = string
}

variable "location" {
  type    = string
  default = "westeurope"
}

variable "region_short" {
  description = "2–3 char region code matching 'location' (e.g. we = westeurope, eus = eastus)"
  type        = string
  default     = "we"
}

variable "instance" {
  description = "3-digit instance suffix (e.g. 001)"
  type        = string
  default     = "001"
}

variable "tags" {
  type    = map(string)
  default = {}
}

# ── HUB NETWORKING ────────────────────────────────────────────
variable "hub_vnet_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "hub_subnet_cidrs" {
  type = object({
    firewall    = string   # AzureFirewallSubnet  (name fixed by Azure)
    gateway     = string   # GatewaySubnet         (name fixed by Azure)
    bastion     = string   # AzureBastionSubnet    (name fixed by Azure)
    app_gateway = string
    apim        = string
    management  = string
  })
  default = {
    firewall    = "10.0.0.0/26"
    gateway     = "10.0.1.0/27"
    bastion     = "10.0.2.0/26"
    app_gateway = "10.0.3.0/24"
    apim        = "10.0.4.0/28"
    management  = "10.0.5.0/24"
  }
}

# ── FEATURE FLAGS ─────────────────────────────────────────────
variable "enable_firewall"    { type = bool; default = true }
variable "enable_app_gateway" { type = bool; default = true }
variable "enable_vpn_gateway" { type = bool; default = false }
variable "enable_bastion"     { type = bool; default = true }
variable "enable_apim"        { type = bool; default = true }
variable "enable_jumpbox"     { type = bool; default = true }
variable "enable_agent_vm"    { type = bool; default = true }

# ── HUB SERVICE CONFIGS ───────────────────────────────────────
variable "firewall_sku_tier"          { type = string; default = "Standard" }
variable "firewall_network_rules"     { type = any;    default = [] }
variable "firewall_application_rules" { type = any;    default = [] }

variable "app_gateway_sku_name"      { type = string;            default = "WAF_v2" }
variable "app_gateway_sku_tier"      { type = string;            default = "WAF_v2" }
variable "app_gateway_capacity"      { type = number;            default = 2 }
variable "app_gateway_backend_pools" { type = map(list(string)); default = {} }

variable "vpn_gateway_sku" { type = string; default = "VpnGw1" }

variable "apim_publisher_name"  { type = string; default = "My Organisation" }
variable "apim_publisher_email" { type = string; default = "platform@example.com" }
variable "apim_sku_name"        { type = string; default = "Developer_1" }

variable "acr_sku" { type = string; default = "Premium" }

variable "jumpbox_vm_size"   { type = string; default = "Standard_D2s_v3" }
variable "agent_vm_size"     { type = string; default = "Standard_D4s_v3" }
variable "vm_admin_username" { type = string; default = "azureadmin" }
variable "vm_admin_password" { type = string; sensitive = true; default = "" }
variable "vm_ssh_public_key" { type = string; default = "" }
