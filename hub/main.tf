# =============================================================
# HUB ROOT — deploys against the Hub subscription
#
# Usage:
#   az login
#   az account set --subscription <hub-subscription-id>
#   terraform init  -backend-config="../subscriptions/hub/backend.tfvars"
#   terraform apply -var-file="../subscriptions/hub/values.tfvars"
# =============================================================

# Provides the current tenant_id for Key Vault — must be at the top
# because module.key_vault references it
data "azurerm_client_config" "current" {}

# ── RESOURCE GROUPS ──────────────────────────────────────────
module "hub_rg" {
  source   = "../modules/resource_group"
  name     = local.hub_rg_name          # rg-qoc-hub-we-001
  location = var.location
  tags     = local.common_tags
}

module "pdns_rg" {
  source   = "../modules/resource_group"
  name     = local.pdns_rg_name         # rg-pdns-qoc-hub-we-001
  location = var.location
  tags     = local.common_tags
}

# ── HUB VIRTUAL NETWORK ───────────────────────────────────────
module "hub_vnet" {
  source              = "../modules/virtual_network"
  name                = "vnet-${local.hub_suffix}"     # vnet-qoc-hub-we-001
  resource_group_name = module.hub_rg.name
  location            = var.location
  address_space       = [var.hub_vnet_cidr]
  tags                = local.common_tags
}

# ── HUB NSGs ─────────────────────────────────────────────────
module "nsg_mgmt" {
  source              = "../modules/network_security_group"
  name                = "nsg-mgmt-${local.hub_suffix}"  # nsg-mgmt-qoc-hub-we-001
  resource_group_name = module.hub_rg.name
  location            = var.location
  tags                = local.common_tags
  security_rules = [
    {
      name                       = "AllowBastionRDP"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "3389"
      destination_port_ranges    = null
      source_address_prefix      = var.hub_subnet_cidrs.bastion
      destination_address_prefix = var.hub_subnet_cidrs.management
    },
    {
      name                       = "AllowBastionSSH"
      priority                   = 110
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "22"
      destination_port_ranges    = null
      source_address_prefix      = var.hub_subnet_cidrs.bastion
      destination_address_prefix = var.hub_subnet_cidrs.management
    },
    {
      name                       = "DenyAllInbound"
      priority                   = 4096
      direction                  = "Inbound"
      access                     = "Deny"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      destination_port_ranges    = null
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    },
  ]
}

module "nsg_appgw" {
  source              = "../modules/network_security_group"
  name                = "nsg-appgw-${local.hub_suffix}"  # nsg-appgw-qoc-hub-we-001
  resource_group_name = module.hub_rg.name
  location            = var.location
  tags                = local.common_tags
  security_rules = [
    {
      name                       = "AllowGatewayManager"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "65200-65535"
      destination_port_ranges    = null
      source_address_prefix      = "GatewayManager"
      destination_address_prefix = "*"
    },
    {
      name                       = "AllowHTTPHTTPS"
      priority                   = 110
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = null
      destination_port_ranges    = ["80", "443"]
      source_address_prefix      = "Internet"
      destination_address_prefix = "*"
    },
    {
      name                       = "AllowAzureLoadBalancer"
      priority                   = 120
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      destination_port_ranges    = null
      source_address_prefix      = "AzureLoadBalancer"
      destination_address_prefix = "*"
    },
  ]
}

module "nsg_apim" {
  source              = "../modules/network_security_group"
  name                = "nsg-apim-${local.hub_suffix}"  # nsg-apim-qoc-hub-we-001
  resource_group_name = module.hub_rg.name
  location            = var.location
  tags                = local.common_tags
  security_rules = [
    {
      name                       = "AllowAPIMManagementInbound"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "3443"
      destination_port_ranges    = null
      source_address_prefix      = "ApiManagement"
      destination_address_prefix = "VirtualNetwork"
    },
    {
      name                       = "AllowAppGatewayToAPIM"
      priority                   = 110
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      destination_port_ranges    = null
      source_address_prefix      = var.hub_subnet_cidrs.app_gateway
      destination_address_prefix = "VirtualNetwork"
    },
    {
      name                       = "AllowAzureLoadBalancer"
      priority                   = 120
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "6390"
      destination_port_ranges    = null
      source_address_prefix      = "AzureLoadBalancer"
      destination_address_prefix = "VirtualNetwork"
    },
    {
      name                       = "AllowAPIMOutboundStorage"
      priority                   = 100
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      destination_port_ranges    = null
      source_address_prefix      = "VirtualNetwork"
      destination_address_prefix = "Storage"
    },
    {
      name                       = "AllowAPIMOutboundSQL"
      priority                   = 110
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "1433"
      destination_port_ranges    = null
      source_address_prefix      = "VirtualNetwork"
      destination_address_prefix = "Sql"
    },
    {
      name                       = "AllowAPIMOutboundKeyVault"
      priority                   = 120
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      destination_port_ranges    = null
      source_address_prefix      = "VirtualNetwork"
      destination_address_prefix = "AzureKeyVault"
    },
  ]
}

# ── HUB SUBNETS ───────────────────────────────────────────────
# Azure-reserved subnet names cannot be renamed
module "snet_firewall" {
  source               = "../modules/subnet"
  name                 = "AzureFirewallSubnet"
  resource_group_name  = module.hub_rg.name
  virtual_network_name = module.hub_vnet.name
  address_prefix       = var.hub_subnet_cidrs.firewall
}

module "snet_gateway" {
  source               = "../modules/subnet"
  name                 = "GatewaySubnet"
  resource_group_name  = module.hub_rg.name
  virtual_network_name = module.hub_vnet.name
  address_prefix       = var.hub_subnet_cidrs.gateway
}

module "snet_bastion" {
  source               = "../modules/subnet"
  name                 = "AzureBastionSubnet"
  resource_group_name  = module.hub_rg.name
  virtual_network_name = module.hub_vnet.name
  address_prefix       = var.hub_subnet_cidrs.bastion
}

module "snet_appgw" {
  source               = "../modules/subnet"
  name                 = "snet-appgw-${local.hub_suffix}"   # snet-appgw-qoc-hub-we-001
  resource_group_name  = module.hub_rg.name
  virtual_network_name = module.hub_vnet.name
  address_prefix       = var.hub_subnet_cidrs.app_gateway
  nsg_id               = module.nsg_appgw.id
}

module "snet_apim" {
  source               = "../modules/subnet"
  name                 = "snet-apim-${local.hub_suffix}"    # snet-apim-qoc-hub-we-001
  resource_group_name  = module.hub_rg.name
  virtual_network_name = module.hub_vnet.name
  address_prefix       = var.hub_subnet_cidrs.apim
  nsg_id               = module.nsg_apim.id
}

module "snet_mgmt" {
  source               = "../modules/subnet"
  name                 = "snet-mgmt-${local.hub_suffix}"    # snet-mgmt-qoc-hub-we-001
  resource_group_name  = module.hub_rg.name
  virtual_network_name = module.hub_vnet.name
  address_prefix       = var.hub_subnet_cidrs.management
  nsg_id               = module.nsg_mgmt.id
}

# ── HUB SERVICES ─────────────────────────────────────────────
module "firewall" {
  count               = var.enable_firewall ? 1 : 0
  source              = "../modules/firewall"
  name                = "azfw-${local.hub_suffix}"          # azfw-qoc-hub-we-001
  resource_group_name = module.hub_rg.name
  location            = var.location
  subnet_id           = module.snet_firewall.id
  sku_tier            = var.firewall_sku_tier
  tags                = local.common_tags
  network_rules       = var.firewall_network_rules
  application_rules   = var.firewall_application_rules
}

module "application_gateway" {
  count               = var.enable_app_gateway ? 1 : 0
  source              = "../modules/application_gateway"
  name                = "agw-${local.hub_suffix}"           # agw-qoc-hub-we-001
  resource_group_name = module.hub_rg.name
  location            = var.location
  subnet_id           = module.snet_appgw.id
  sku_name            = var.app_gateway_sku_name
  sku_tier            = var.app_gateway_sku_tier
  capacity            = var.app_gateway_capacity
  backend_pools       = var.app_gateway_backend_pools
  tags                = local.common_tags
}

module "vpn_gateway" {
  count               = var.enable_vpn_gateway ? 1 : 0
  source              = "../modules/vpn_gateway"
  name                = "vpng-${local.hub_suffix}"          # vpng-qoc-hub-we-001
  resource_group_name = module.hub_rg.name
  location            = var.location
  subnet_id           = module.snet_gateway.id
  sku                 = var.vpn_gateway_sku
  tags                = local.common_tags
}

module "bastion" {
  count               = var.enable_bastion ? 1 : 0
  source              = "../modules/bastion"
  name                = "bas-${local.hub_suffix}"           # bas-qoc-hub-we-001
  resource_group_name = module.hub_rg.name
  location            = var.location
  subnet_id           = module.snet_bastion.id
  tags                = local.common_tags
}

module "apim" {
  count                = var.enable_apim ? 1 : 0
  source               = "../modules/apim"
  name                 = "apim-${local.hub_suffix}"         # apim-qoc-hub-we-001
  resource_group_name  = module.hub_rg.name
  location             = var.location
  publisher_name       = var.apim_publisher_name
  publisher_email      = var.apim_publisher_email
  sku_name             = var.apim_sku_name
  subnet_id            = module.snet_apim.id
  virtual_network_type = "Internal"
  tags                 = local.common_tags
}

# Hub Key Vault — platform secrets (certs, pipeline credentials)
# PE lives in the management subnet so hub VMs can resolve it
module "key_vault" {
  source                     = "../modules/key_vault"
  name                       = "kv-${local.hub_suffix}"       # kv-qoc-hub-we-001
  resource_group_name        = module.hub_rg.name
  location                   = var.location
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  private_endpoint_subnet_id = module.snet_mgmt.id
  private_dns_zone_id        = module.dns_keyvault.id
  network_acls_subnet_ids    = [module.snet_mgmt.id]
  tags                       = local.common_tags
}

# Hub Container Registry — shared image registry for all spokes
# PE lives in the management subnet
module "container_registry" {
  source                     = "../modules/container_registry"
  name                       = "acr-${local.hub_suffix}"      # acr-qoc-hub-we-001
  resource_group_name        = module.hub_rg.name
  location                   = var.location
  sku                        = var.acr_sku
  private_endpoint_subnet_id = module.snet_mgmt.id
  private_dns_zone_id        = module.dns_acr.id
  tags                       = local.common_tags
}

module "jumpbox_vm" {
  count               = var.enable_jumpbox ? 1 : 0
  source              = "../modules/jumpbox_vm"
  name                = "vm-jmp-${local.hub_suffix}"          # vm-jmp-qoc-hub-we-001
  resource_group_name = module.hub_rg.name
  location            = var.location
  subnet_id           = module.snet_mgmt.id
  vm_size             = var.jumpbox_vm_size
  admin_username      = var.vm_admin_username
  admin_password      = var.vm_admin_password
  tags                = local.common_tags
}

module "agent_vm" {
  count               = var.enable_agent_vm ? 1 : 0
  source              = "../modules/agent_vm"
  name                = "vm-agt-${local.hub_suffix}"          # vm-agt-qoc-hub-we-001
  resource_group_name = module.hub_rg.name
  location            = var.location
  subnet_id           = module.snet_mgmt.id
  vm_size             = var.agent_vm_size
  admin_username      = var.vm_admin_username
  ssh_public_key      = var.vm_ssh_public_key
  tags                = local.common_tags
}

# ── PRIVATE DNS ZONES (hub-side: KV and ACR only) ────────────
# Linked to hub VNet so management VMs can resolve hub services.
# Spoke DNS zones (for all workloads) are created by the spoke deployment.

module "dns_keyvault" {
  source              = "../modules/private_dns_zone"
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = module.pdns_rg.name
  vnet_links          = { hub = module.hub_vnet.id }
  tags                = local.common_tags
}

module "dns_acr" {
  source              = "../modules/private_dns_zone"
  name                = "privatelink.azurecr.io"
  resource_group_name = module.pdns_rg.name
  vnet_links          = { hub = module.hub_vnet.id }
  tags                = local.common_tags
}
