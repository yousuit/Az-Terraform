# =============================================================
# SPOKE ROOT — deploys against a Dev / Staging / Prod subscription
#
# Usage:
#   az login
#   az account set --subscription <spoke-subscription-id>
#   terraform init  -backend-config="../subscriptions/<env>/backend.tfvars"
#   terraform apply -var-file="../subscriptions/<env>/values.tfvars" \
#                   -var="sql_admin_password=<secret>"
#
# Prerequisites:
#   1. Hub must be deployed first — copy terraform output values into
#      subscriptions/<env>/values.tfvars (hub_vnet_id, hub_keyvault_id, etc.)
# =============================================================

# ── RESOURCE GROUPS ──────────────────────────────────────────
module "spoke_rg" {
  source   = "../modules/resource_group"
  name     = local.spoke_rg_name # rg-web-qoc-we-prod-001
  location = var.location
  tags     = local.common_tags
}

module "pdns_rg" {
  source   = "../modules/resource_group"
  name     = local.pdns_rg_name # rg-pdns-qoc-we-prod-001
  location = var.location
  tags     = local.common_tags
}

# ── SPOKE VIRTUAL NETWORK ─────────────────────────────────────
module "spoke_vnet" {
  source              = "../modules/virtual_network"
  name                = "vnet-${local.spoke_suffix}" # vnet-qoc-we-prod-001
  resource_group_name = module.spoke_rg.name
  location            = var.location
  address_space       = [var.spoke_vnet_cidr]
  tags                = local.common_tags
}

# ── SPOKE NSGs ────────────────────────────────────────────────
module "nsg_app" {
  source              = "../modules/network_security_group"
  name                = "nsg-app-${local.spoke_suffix}" # nsg-app-qoc-we-prod-001
  resource_group_name = module.spoke_rg.name
  location            = var.location
  tags                = local.common_tags
  # Outbound-only subnet — deny all inbound, App Service VNet integration is outbound
  security_rules = [
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

module "nsg_func" {
  source              = "../modules/network_security_group"
  name                = "nsg-func-${local.spoke_suffix}" # nsg-func-qoc-we-prod-001
  resource_group_name = module.spoke_rg.name
  location            = var.location
  tags                = local.common_tags
  # Outbound-only subnet — deny all inbound, Function App VNet integration is outbound
  security_rules = [
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

module "nsg_pe" {
  source              = "../modules/network_security_group"
  name                = "nsg-pe-${local.spoke_suffix}" # nsg-pe-qoc-we-prod-001
  resource_group_name = module.spoke_rg.name
  location            = var.location
  tags                = local.common_tags
  security_rules = [
    {
      name                       = "AllowVnetInbound"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      destination_port_ranges    = null
      source_address_prefix      = "VirtualNetwork"
      destination_address_prefix = "VirtualNetwork"
    },
    {
      name                       = "DenyInternetInbound"
      priority                   = 4096
      direction                  = "Inbound"
      access                     = "Deny"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      destination_port_ranges    = null
      source_address_prefix      = "Internet"
      destination_address_prefix = "*"
    },
  ]
}

module "nsg_dbk_pub" {
  source              = "../modules/network_security_group"
  name                = "nsg-dbkpub-${local.spoke_suffix}" # nsg-dbkpub-qoc-we-prod-001
  resource_group_name = module.spoke_rg.name
  location            = var.location
  tags                = local.common_tags
  security_rules      = [] # Databricks manages its own rules
}

module "nsg_dbk_prv" {
  source              = "../modules/network_security_group"
  name                = "nsg-dbkprv-${local.spoke_suffix}" # nsg-dbkprv-qoc-we-prod-001
  resource_group_name = module.spoke_rg.name
  location            = var.location
  tags                = local.common_tags
  security_rules      = [] # Databricks manages its own rules
}

module "nsg_mysql" {
  source              = "../modules/network_security_group"
  name                = "nsg-mysql-${local.spoke_suffix}" # nsg-mysql-qoc-we-prod-001
  resource_group_name = module.spoke_rg.name
  location            = var.location
  tags                = local.common_tags
  security_rules = [
    {
      name                       = "AllowVnetMySQL"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "3306"
      destination_port_ranges    = null
      source_address_prefix      = "VirtualNetwork"
      destination_address_prefix = "*"
    },
    {
      name                       = "DenyInternetInbound"
      priority                   = 4096
      direction                  = "Inbound"
      access                     = "Deny"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      destination_port_ranges    = null
      source_address_prefix      = "Internet"
      destination_address_prefix = "*"
    },
  ]
}

module "nsg_psql" {
  source              = "../modules/network_security_group"
  name                = "nsg-psql-${local.spoke_suffix}" # nsg-psql-qoc-we-prod-001
  resource_group_name = module.spoke_rg.name
  location            = var.location
  tags                = local.common_tags
  security_rules = [
    {
      name                       = "AllowVnetPostgreSQL"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "5432"
      destination_port_ranges    = null
      source_address_prefix      = "VirtualNetwork"
      destination_address_prefix = "*"
    },
    {
      name                       = "DenyInternetInbound"
      priority                   = 4096
      direction                  = "Inbound"
      access                     = "Deny"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      destination_port_ranges    = null
      source_address_prefix      = "Internet"
      destination_address_prefix = "*"
    },
  ]
}

module "nsg_aci" {
  source              = "../modules/network_security_group"
  name                = "nsg-aci-${local.spoke_suffix}" # nsg-aci-qoc-we-prod-001
  resource_group_name = module.spoke_rg.name
  location            = var.location
  tags                = local.common_tags
  security_rules = [
    {
      name                       = "AllowVnetInbound"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      destination_port_ranges    = null
      source_address_prefix      = "VirtualNetwork"
      destination_address_prefix = "*"
    },
    {
      name                       = "DenyInternetInbound"
      priority                   = 4096
      direction                  = "Inbound"
      access                     = "Deny"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      destination_port_ranges    = null
      source_address_prefix      = "Internet"
      destination_address_prefix = "*"
    },
  ]
}

module "nsg_aif" {
  source              = "../modules/network_security_group"
  name                = "nsg-aif-${local.spoke_suffix}" # nsg-aif-qoc-we-prod-001
  resource_group_name = module.spoke_rg.name
  location            = var.location
  tags                = local.common_tags
  security_rules = [
    {
      name                       = "AllowVnetInbound"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      destination_port_ranges    = null
      source_address_prefix      = "VirtualNetwork"
      destination_address_prefix = "*"
    },
    {
      name                       = "DenyInternetInbound"
      priority                   = 4096
      direction                  = "Inbound"
      access                     = "Deny"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      destination_port_ranges    = null
      source_address_prefix      = "Internet"
      destination_address_prefix = "*"
    },
  ]
}

# ── SPOKE SUBNETS ─────────────────────────────────────────────
# App Service and Function App: outbound VNet integration (delegation required)
# Inbound access is via private endpoint in snet-pe
module "snet_app" {
  source               = "../modules/subnet"
  name                 = "snet-app-${local.spoke_suffix}" # snet-app-qoc-we-prod-001
  resource_group_name  = module.spoke_rg.name
  virtual_network_name = module.spoke_vnet.name
  address_prefix       = var.spoke_subnet_cidrs.app_service_vnetint
  nsg_id               = module.nsg_app.id
  route_table_id       = module.udr.id
  delegation = {
    name    = "app-service-delegation"
    service = "Microsoft.Web/serverFarms"
    actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
  }
}

module "snet_func" {
  source               = "../modules/subnet"
  name                 = "snet-func-${local.spoke_suffix}" # snet-func-qoc-we-prod-001
  resource_group_name  = module.spoke_rg.name
  virtual_network_name = module.spoke_vnet.name
  address_prefix       = var.spoke_subnet_cidrs.function_app_vnetint
  nsg_id               = module.nsg_func.id
  route_table_id       = module.udr.id
  delegation = {
    name    = "function-app-delegation"
    service = "Microsoft.Web/serverFarms"
    actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
  }
}

# Shared PE subnet — PE network policies disabled so private endpoints resolve correctly
module "snet_pe" {
  source                                    = "../modules/subnet"
  name                                      = "snet-pe-${local.spoke_suffix}" # snet-pe-qoc-we-prod-001
  resource_group_name                       = module.spoke_rg.name
  virtual_network_name                      = module.spoke_vnet.name
  address_prefix                            = var.spoke_subnet_cidrs.private_endpoints
  nsg_id                                    = module.nsg_pe.id
  private_endpoint_network_policies_enabled = false
}

module "snet_dbk_pub" {
  source               = "../modules/subnet"
  name                 = "snet-dbkpub-${local.spoke_suffix}" # snet-dbkpub-qoc-we-prod-001
  resource_group_name  = module.spoke_rg.name
  virtual_network_name = module.spoke_vnet.name
  address_prefix       = var.spoke_subnet_cidrs.databricks_public
  nsg_id               = module.nsg_dbk_pub.id
  delegation = {
    name    = "databricks-delegation"
    service = "Microsoft.Databricks/workspaces"
    actions = [
      "Microsoft.Network/virtualNetworks/subnets/join/action",
      "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
      "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action",
    ]
  }
}

module "snet_dbk_prv" {
  source               = "../modules/subnet"
  name                 = "snet-dbkprv-${local.spoke_suffix}" # snet-dbkprv-qoc-we-prod-001
  resource_group_name  = module.spoke_rg.name
  virtual_network_name = module.spoke_vnet.name
  address_prefix       = var.spoke_subnet_cidrs.databricks_private
  nsg_id               = module.nsg_dbk_prv.id
  delegation = {
    name    = "databricks-delegation"
    service = "Microsoft.Databricks/workspaces"
    actions = [
      "Microsoft.Network/virtualNetworks/subnets/join/action",
      "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
      "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action",
    ]
  }
}

# SQL MI: no nsg_id here — the sql_managed_instance module creates and associates its own NSG + UDR
module "snet_sqlmi" {
  source               = "../modules/subnet"
  name                 = "snet-sqlmi-${local.spoke_suffix}" # snet-sqlmi-qoc-we-prod-001
  resource_group_name  = module.spoke_rg.name
  virtual_network_name = module.spoke_vnet.name
  address_prefix       = var.spoke_subnet_cidrs.sql_mi
  delegation = {
    name    = "sql-mi-delegation"
    service = "Microsoft.Sql/managedInstances"
    actions = [
      "Microsoft.Network/virtualNetworks/subnets/join/action",
      "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
      "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action",
    ]
  }
}

# MySQL and PostgreSQL Flexible: VNet injection via dedicated delegated subnet (no private endpoint)
module "snet_mysql" {
  source               = "../modules/subnet"
  name                 = "snet-mysql-${local.spoke_suffix}" # snet-mysql-qoc-we-prod-001
  resource_group_name  = module.spoke_rg.name
  virtual_network_name = module.spoke_vnet.name
  address_prefix       = var.spoke_subnet_cidrs.mysql_flexible
  nsg_id               = module.nsg_mysql.id
  delegation = {
    name    = "mysql-flexible-delegation"
    service = "Microsoft.DBforMySQL/flexibleServers"
    actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
  }
}

module "snet_psql" {
  source               = "../modules/subnet"
  name                 = "snet-psql-${local.spoke_suffix}" # snet-psql-qoc-we-prod-001
  resource_group_name  = module.spoke_rg.name
  virtual_network_name = module.spoke_vnet.name
  address_prefix       = var.spoke_subnet_cidrs.postgresql_flexible
  nsg_id               = module.nsg_psql.id
  delegation = {
    name    = "psql-flexible-delegation"
    service = "Microsoft.DBforPostgreSQL/flexibleServers"
    actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
  }
}

# Container Instance: VNet injection via dedicated delegated subnet
module "snet_aci" {
  source               = "../modules/subnet"
  name                 = "snet-aci-${local.spoke_suffix}" # snet-aci-qoc-we-prod-001
  resource_group_name  = module.spoke_rg.name
  virtual_network_name = module.spoke_vnet.name
  address_prefix       = var.spoke_subnet_cidrs.container_instances
  nsg_id               = module.nsg_aci.id
  delegation = {
    name    = "aci-delegation"
    service = "Microsoft.ContainerInstance/containerGroups"
    actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
  }
}

# AI Foundry compute clusters / online endpoints: VNet injection
module "snet_aif" {
  source               = "../modules/subnet"
  name                 = "snet-aif-${local.spoke_suffix}" # snet-aif-qoc-we-prod-001
  resource_group_name  = module.spoke_rg.name
  virtual_network_name = module.spoke_vnet.name
  address_prefix       = var.spoke_subnet_cidrs.ai_foundry_compute
  nsg_id               = module.nsg_aif.id
}

# ── UDR — force all egress through hub firewall ───────────────
module "udr" {
  source              = "../modules/route_table"
  name                = "rt-${local.spoke_suffix}" # rt-qoc-we-prod-001
  resource_group_name = module.spoke_rg.name
  location            = var.location
  tags                = local.common_tags
  routes = [
    {
      name                   = "to-hub-firewall"
      address_prefix         = "0.0.0.0/0"
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = var.hub_firewall_private_ip
    }
  ]
}

# ── VNET PEERING (bidirectional, cross-subscription) ─────────
# spoke → hub: created with the spoke (default) provider
resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  name                      = "${module.spoke_vnet.name}-to-hub"
  resource_group_name       = module.spoke_rg.name
  virtual_network_name      = module.spoke_vnet.name
  remote_virtual_network_id = var.hub_vnet_id
  allow_forwarded_traffic   = true
  use_remote_gateways       = false
}

# hub → spoke: created with the hub provider alias (cross-subscription)
resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  provider                  = azurerm.hub
  name                      = "hub-to-${module.spoke_vnet.name}"
  resource_group_name       = var.hub_rg_name
  virtual_network_name      = var.hub_vnet_name
  remote_virtual_network_id = module.spoke_vnet.id
  allow_forwarded_traffic   = true
  allow_gateway_transit     = true
}

# ── PRIVATE DNS ZONES ─────────────────────────────────────────
# All zones are in the spoke PDNS RG and linked to spoke VNet.
# When link_dns_to_hub_vnet = true, they are also linked to hub VNet
# so management VMs can resolve spoke service hostnames.
# The dns_vnet_links local handles both cases (see locals.tf).

module "dns_blob" {
  source              = "../modules/private_dns_zone"
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = module.pdns_rg.name
  vnet_links          = local.dns_vnet_links
  tags                = local.common_tags
}

module "dns_file" {
  source              = "../modules/private_dns_zone"
  name                = "privatelink.file.core.windows.net"
  resource_group_name = module.pdns_rg.name
  vnet_links          = local.dns_vnet_links
  tags                = local.common_tags
}

module "dns_queue" {
  source              = "../modules/private_dns_zone"
  name                = "privatelink.queue.core.windows.net"
  resource_group_name = module.pdns_rg.name
  vnet_links          = local.dns_vnet_links
  tags                = local.common_tags
}

module "dns_table" {
  source              = "../modules/private_dns_zone"
  name                = "privatelink.table.core.windows.net"
  resource_group_name = module.pdns_rg.name
  vnet_links          = local.dns_vnet_links
  tags                = local.common_tags
}

# App Service and Function App share this DNS zone (both use azurewebsites.net)
module "dns_websites" {
  source              = "../modules/private_dns_zone"
  name                = "privatelink.azurewebsites.net"
  resource_group_name = module.pdns_rg.name
  vnet_links          = local.dns_vnet_links
  tags                = local.common_tags
}

module "dns_redis" {
  source              = "../modules/private_dns_zone"
  name                = "privatelink.redis.cache.windows.net"
  resource_group_name = module.pdns_rg.name
  vnet_links          = local.dns_vnet_links
  tags                = local.common_tags
}

module "dns_sql" {
  source              = "../modules/private_dns_zone"
  name                = "privatelink.database.windows.net"
  resource_group_name = module.pdns_rg.name
  vnet_links          = local.dns_vnet_links
  tags                = local.common_tags
}

module "dns_servicebus" {
  source              = "../modules/private_dns_zone"
  name                = "privatelink.servicebus.windows.net"
  resource_group_name = module.pdns_rg.name
  vnet_links          = local.dns_vnet_links
  tags                = local.common_tags
}

module "dns_eventgrid" {
  source              = "../modules/private_dns_zone"
  name                = "privatelink.eventgrid.azure.net"
  resource_group_name = module.pdns_rg.name
  vnet_links          = local.dns_vnet_links
  tags                = local.common_tags
}

module "dns_openai" {
  source              = "../modules/private_dns_zone"
  name                = "privatelink.openai.azure.com"
  resource_group_name = module.pdns_rg.name
  vnet_links          = local.dns_vnet_links
  tags                = local.common_tags
}

# Speech, AI Vision share this zone
module "dns_cognitiveservices" {
  source              = "../modules/private_dns_zone"
  name                = "privatelink.cognitiveservices.azure.com"
  resource_group_name = module.pdns_rg.name
  vnet_links          = local.dns_vnet_links
  tags                = local.common_tags
}

module "dns_search" {
  source              = "../modules/private_dns_zone"
  name                = "privatelink.search.windows.net"
  resource_group_name = module.pdns_rg.name
  vnet_links          = local.dns_vnet_links
  tags                = local.common_tags
}

# MySQL Flexible — VNet injection uses private DNS for server resolution
module "dns_mysql" {
  source              = "../modules/private_dns_zone"
  name                = "privatelink.mysql.database.azure.com"
  resource_group_name = module.pdns_rg.name
  vnet_links          = local.dns_vnet_links
  tags                = local.common_tags
}

# PostgreSQL Flexible — VNet injection uses private DNS for server resolution
module "dns_postgresql" {
  source              = "../modules/private_dns_zone"
  name                = "privatelink.postgres.database.azure.com"
  resource_group_name = module.pdns_rg.name
  vnet_links          = local.dns_vnet_links
  tags                = local.common_tags
}

# CosmosDB NoSQL
module "dns_cosmos_nosql" {
  source              = "../modules/private_dns_zone"
  name                = "privatelink.documents.azure.com"
  resource_group_name = module.pdns_rg.name
  vnet_links          = local.dns_vnet_links
  tags                = local.common_tags
}

# CosmosDB Mongo uses a DIFFERENT zone from NoSQL
module "dns_cosmos_mongo" {
  source              = "../modules/private_dns_zone"
  name                = "privatelink.mongo.cosmos.azure.com"
  resource_group_name = module.pdns_rg.name
  vnet_links          = local.dns_vnet_links
  tags                = local.common_tags
}

# AI Foundry requires two separate DNS zones
module "dns_aml_api" {
  source              = "../modules/private_dns_zone"
  name                = "privatelink.api.azureml.ms"
  resource_group_name = module.pdns_rg.name
  vnet_links          = local.dns_vnet_links
  tags                = local.common_tags
}

module "dns_aml_notebooks" {
  source              = "../modules/private_dns_zone"
  name                = "privatelink.notebooks.azure.net"
  resource_group_name = module.pdns_rg.name
  vnet_links          = local.dns_vnet_links
  tags                = local.common_tags
}

# ── MONITORING (deploy before all workloads) ──────────────────
module "monitoring" {
  source              = "../modules/monitoring"
  name                = "${var.project}-${local.spoke_suffix}" # web-qoc-we-prod-001
  resource_group_name = module.spoke_rg.name
  location            = var.location
  retention_days      = var.log_retention_days
  tags                = local.common_tags
}

# ── WORKLOADS ─────────────────────────────────────────────────

# App Service Plan + Web Apps
# Naming: module creates "${name}-${each.key}"
#   name = "app"  +  app_names = ["fe-qoc-we-prod-001"]
#   → individual app: app-fe-qoc-we-prod-001  ✓
#   → service plan:   app-asp
# VNet: outbound via snet-app (VNet integration), inbound via snet-pe (private endpoint)
module "app_service" {
  count                          = var.enable_app_service ? 1 : 0
  source                         = "../modules/app_service"
  name                           = "app"
  app_names                      = [for n in var.app_service_names : "${n}-${local.spoke_suffix}"]
  resource_group_name            = module.spoke_rg.name
  location                       = var.location
  sku_name                       = var.app_service_sku
  vnet_integration_subnet_id     = module.snet_app.id
  private_endpoint_subnet_id     = module.snet_pe.id
  private_dns_zone_id            = module.dns_websites.id
  app_insights_connection_string = module.monitoring.app_insights_connection_string
  key_vault_id                   = var.hub_keyvault_id
  tags                           = local.common_tags
}

# Function App Plan + Functions
# Naming: func-proc-qoc-we-prod-001, func-notifier-qoc-we-prod-001
# VNet: outbound via snet-func (VNet integration), inbound via snet-pe (private endpoint)
module "function_app" {
  count                          = var.enable_function_app ? 1 : 0
  source                         = "../modules/function_app"
  name                           = "func"
  function_names                 = [for n in var.function_app_names : "${n}-${local.spoke_suffix}"]
  resource_group_name            = module.spoke_rg.name
  location                       = var.location
  sku_name                       = var.function_app_sku
  vnet_integration_subnet_id     = module.snet_func.id
  private_endpoint_subnet_id     = module.snet_pe.id
  private_dns_zone_id            = module.dns_websites.id
  storage_account_name           = module.storage_account[0].name
  storage_account_access_key     = module.storage_account[0].primary_access_key
  app_insights_connection_string = module.monitoring.app_insights_connection_string
  tags                           = local.common_tags
  depends_on                     = [module.storage_account]
}

# Storage Account — private endpoints for blob and file
module "storage_account" {
  count                      = var.enable_storage ? 1 : 0
  source                     = "../modules/storage_account"
  name                       = local.storage_name # stqocwebweprod001
  resource_group_name        = module.spoke_rg.name
  location                   = var.location
  private_endpoint_subnet_id = module.snet_pe.id
  private_dns_zone_blob_id   = module.dns_blob.id
  private_dns_zone_file_id   = module.dns_file.id
  tags                       = local.common_tags
}

# Redis Cache — private endpoint, no VNet injection
module "redis_cache" {
  count                      = var.enable_redis ? 1 : 0
  source                     = "../modules/redis_cache"
  name                       = "redis-${var.project}-${local.spoke_suffix}" # redis-web-qoc-we-prod-001
  resource_group_name        = module.spoke_rg.name
  location                   = var.location
  sku_name                   = var.redis_sku
  capacity                   = var.redis_capacity
  family                     = var.redis_family
  private_endpoint_subnet_id = module.snet_pe.id
  private_dns_zone_id        = module.dns_redis.id
  tags                       = local.common_tags
}

# Azure SQL — private endpoint, no VNet injection
module "sql_database" {
  count                      = var.enable_sql_db ? 1 : 0
  source                     = "../modules/sql_database"
  server_name                = "sql-${var.project}-${local.spoke_suffix}" # sql-web-qoc-we-prod-001
  resource_group_name        = module.spoke_rg.name
  location                   = var.location
  admin_login                = var.sql_admin_login
  admin_password             = var.sql_admin_password
  databases                  = var.sql_databases
  private_endpoint_subnet_id = module.snet_pe.id
  private_dns_zone_id        = module.dns_sql.id
  tags                       = local.common_tags
}

# SQL Managed Instance — VNet injection via dedicated delegated subnet (snet-sqlmi)
# The module creates and associates its own NSG + UDR on the subnet
module "sql_managed_instance" {
  count               = var.enable_sql_mi ? 1 : 0
  source              = "../modules/sql_managed_instance"
  name                = "sqlmi-${var.project}-${local.spoke_suffix}" # sqlmi-web-qoc-we-prod-001
  resource_group_name = module.spoke_rg.name
  location            = var.location
  subnet_id           = module.snet_sqlmi.id
  admin_login         = var.sql_admin_login
  admin_password      = var.sql_admin_password
  sku_name            = var.sql_mi_sku
  vcores              = var.sql_mi_vcores
  storage_size_in_gb  = var.sql_mi_storage_gb
  tags                = local.common_tags
}

# Service Bus — private endpoint
module "service_bus" {
  count                      = var.enable_service_bus ? 1 : 0
  source                     = "../modules/service_bus"
  name                       = "sb-${var.project}-${local.spoke_suffix}" # sb-web-qoc-we-prod-001
  resource_group_name        = module.spoke_rg.name
  location                   = var.location
  sku                        = var.service_bus_sku
  queues                     = var.service_bus_queues
  topics                     = var.service_bus_topics
  private_endpoint_subnet_id = module.snet_pe.id
  private_dns_zone_id        = module.dns_servicebus.id
  tags                       = local.common_tags
}

# Event Grid — private endpoint
module "event_grid" {
  count                      = var.enable_event_grid ? 1 : 0
  source                     = "../modules/event_grid"
  name                       = "evgt-${var.project}-${local.spoke_suffix}" # evgt-web-qoc-we-prod-001
  resource_group_name        = module.spoke_rg.name
  location                   = var.location
  private_endpoint_subnet_id = module.snet_pe.id
  private_dns_zone_id        = module.dns_eventgrid.id
  tags                       = local.common_tags
}

# Azure OpenAI — private endpoint (location is region-constrained, uses var.openai_location)
module "openai" {
  count                      = var.enable_openai ? 1 : 0
  source                     = "../modules/openai"
  name                       = "oai-${var.project}-${local.spoke_suffix}" # oai-web-qoc-we-prod-001
  resource_group_name        = module.spoke_rg.name
  location                   = var.openai_location
  deployments                = var.openai_deployments
  private_endpoint_subnet_id = module.snet_pe.id
  private_dns_zone_id        = module.dns_openai.id
  tags                       = local.common_tags
}

# AI Search — private endpoint
module "search_service" {
  count                      = var.enable_search ? 1 : 0
  source                     = "../modules/search_service"
  name                       = "srch-${var.project}-${local.spoke_suffix}" # srch-web-qoc-we-prod-001
  resource_group_name        = module.spoke_rg.name
  location                   = var.location
  sku                        = var.search_sku
  private_endpoint_subnet_id = module.snet_pe.id
  private_dns_zone_id        = module.dns_search.id
  tags                       = local.common_tags
}

# Azure AI Speech — private endpoint, uses cognitiveservices DNS zone
module "speech_service" {
  count                      = var.enable_speech ? 1 : 0
  source                     = "../modules/speech_service"
  name                       = "spch-${var.project}-${local.spoke_suffix}" # spch-web-qoc-we-prod-001
  resource_group_name        = module.spoke_rg.name
  location                   = var.location
  private_endpoint_subnet_id = module.snet_pe.id
  private_dns_zone_id        = module.dns_cognitiveservices.id
  tags                       = local.common_tags
}

# Azure AI Vision — private endpoint, uses cognitiveservices DNS zone (same as Speech)
module "ai_vision" {
  count                      = var.enable_ai_vision ? 1 : 0
  source                     = "../modules/ai_vision"
  name                       = "aiv-${var.project}-${local.spoke_suffix}" # aiv-web-qoc-we-prod-001
  resource_group_name        = module.spoke_rg.name
  location                   = var.location
  private_endpoint_subnet_id = module.snet_pe.id
  private_dns_zone_id        = module.dns_cognitiveservices.id
  tags                       = local.common_tags
}

# Databricks — VNet injection into dedicated public + private subnets (no private endpoint)
module "databricks" {
  count                 = var.enable_databricks ? 1 : 0
  source                = "../modules/databricks"
  name                  = "dbw-${var.project}-${local.spoke_suffix}" # dbw-web-qoc-we-prod-001
  resource_group_name   = module.spoke_rg.name
  location              = var.location
  vnet_id               = module.spoke_vnet.id
  public_subnet_name    = module.snet_dbk_pub.name
  private_subnet_name   = module.snet_dbk_prv.name
  public_subnet_nsg_id  = module.nsg_dbk_pub.id
  private_subnet_nsg_id = module.nsg_dbk_prv.id
  tags                  = local.common_tags
}

# MySQL Flexible — VNet injection via delegated subnet (not a private endpoint)
# The server is injected directly into the subnet; private DNS resolves the FQDN
module "mysql_flexible" {
  count               = var.enable_mysql_flexible ? 1 : 0
  source              = "../modules/mysql_flexible"
  name                = "mysql-${var.project}-${local.spoke_suffix}" # mysql-web-qoc-we-prod-001
  resource_group_name = module.spoke_rg.name
  location            = var.location
  delegated_subnet_id = module.snet_mysql.id # VNet injection — not a private endpoint
  private_dns_zone_id = module.dns_mysql.id
  admin_login         = var.mysql_admin_login
  admin_password      = var.mysql_admin_password
  sku_name            = var.mysql_sku_name
  mysql_version       = var.mysql_version
  storage_size_gb     = var.mysql_storage_gb
  tags                = local.common_tags
}

# PostgreSQL Flexible — VNet injection via delegated subnet (not a private endpoint)
module "postgresql_flexible" {
  count               = var.enable_postgresql ? 1 : 0
  source              = "../modules/postgresql_flexible"
  name                = "psql-${var.project}-${local.spoke_suffix}" # psql-web-qoc-we-prod-001
  resource_group_name = module.spoke_rg.name
  location            = var.location
  delegated_subnet_id = module.snet_psql.id # VNet injection — not a private endpoint
  private_dns_zone_id = module.dns_postgresql.id
  admin_login         = var.postgresql_admin_login
  admin_password      = var.postgresql_admin_password
  sku_name            = var.postgresql_sku_name
  pg_version          = var.postgresql_version
  storage_mb          = var.postgresql_storage_mb
  tags                = local.common_tags
}

# CosmosDB NoSQL — private endpoint, uses documents.azure.com DNS zone
module "cosmosdb_nosql" {
  count                      = var.enable_cosmosdb_nosql ? 1 : 0
  source                     = "../modules/cosmosdb_nosql"
  name                       = "cosmos-nosql-${var.project}-${local.spoke_suffix}"
  resource_group_name        = module.spoke_rg.name
  location                   = var.location
  private_endpoint_subnet_id = module.snet_pe.id
  private_dns_zone_id        = module.dns_cosmos_nosql.id # privatelink.documents.azure.com
  tags                       = local.common_tags
}

# CosmosDB Mongo — private endpoint, uses mongo.cosmos.azure.com DNS zone (DIFFERENT from NoSQL)
module "cosmosdb_mongo" {
  count                      = var.enable_cosmosdb_mongo ? 1 : 0
  source                     = "../modules/cosmosdb_mongo"
  name                       = "cosmos-mongo-${var.project}-${local.spoke_suffix}"
  resource_group_name        = module.spoke_rg.name
  location                   = var.location
  private_endpoint_subnet_id = module.snet_pe.id
  private_dns_zone_id        = module.dns_cosmos_mongo.id # privatelink.mongo.cosmos.azure.com
  tags                       = local.common_tags
}

# AI Foundry (Azure Machine Learning workspace)
# Requires: storage account + key vault + app insights (pre-existing dependencies)
# VNet: compute subnet for clusters/endpoints + PE subnet for workspace inbound
# DNS: two zones — api.azureml.ms + notebooks.azure.net
module "ai_foundry" {
  count                         = var.enable_ai_foundry ? 1 : 0
  source                        = "../modules/ai_foundry"
  name                          = "aif-${var.project}-${local.spoke_suffix}" # aif-web-qoc-we-prod-001
  resource_group_name           = module.spoke_rg.name
  location                      = var.location
  compute_subnet_id             = module.snet_aif.id           # VNet injection for compute clusters
  private_endpoint_subnet_id    = module.snet_pe.id            # Inbound PE for the workspace
  private_dns_zone_api_id       = module.dns_aml_api.id        # privatelink.api.azureml.ms
  private_dns_zone_notebooks_id = module.dns_aml_notebooks.id  # privatelink.notebooks.azure.net
  storage_account_id            = module.storage_account[0].id # requires enable_storage = true
  key_vault_id                  = var.hub_keyvault_id
  application_insights_id       = module.monitoring.app_insights_id
  container_registry_id         = ""
  tags                          = local.common_tags
  depends_on                    = [module.storage_account]
}

# Container Instance — VNet injection via delegated subnet (no private endpoint)
# Requires: containers variable to be set in values.tfvars when enable_container_instance = true
module "container_instance" {
  count               = var.enable_container_instance ? 1 : 0
  source              = "../modules/container_instance"
  name                = "aci-${var.project}-${local.spoke_suffix}" # aci-web-qoc-we-prod-001
  resource_group_name = module.spoke_rg.name
  location            = var.location
  subnet_id           = module.snet_aci.id
  containers          = var.container_instance_containers
  tags                = local.common_tags
}

# Bing Search — no VNet integration (uses public endpoint, billed per call)
module "bing_search" {
  count               = var.enable_bing_search ? 1 : 0
  source              = "../modules/bing_search"
  name                = "bing-${var.project}-${local.spoke_suffix}" # bing-web-qoc-we-prod-001
  resource_group_name = module.spoke_rg.name
  location            = "global"
  tags                = local.common_tags
}
