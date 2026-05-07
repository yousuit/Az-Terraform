resource "azurerm_service_plan" "this" {
  name                = "${var.name}-asp"
  location            = var.location
  resource_group_name = var.resource_group_name
  os_type             = "Linux"
  sku_name            = var.sku_name
  tags                = var.tags
}

resource "azurerm_linux_function_app" "this" {
  for_each            = { for n in var.function_names : n => n }
  name                = "${var.name}-${each.key}"
  location            = var.location
  resource_group_name = var.resource_group_name
  service_plan_id     = azurerm_service_plan.this.id
  tags                = var.tags

  storage_account_name          = var.storage_account_name
  storage_account_access_key    = var.storage_account_access_key
  virtual_network_subnet_id     = var.vnet_integration_subnet_id
  https_only                    = true
  public_network_access_enabled = false

  site_config {
    always_on              = true
    ftps_state             = "Disabled"
    minimum_tls_version    = "1.2"
    vnet_route_all_enabled = true

    application_stack {
      node_version = "20"
    }
  }

  app_settings = merge(var.app_settings, {
    APPLICATIONINSIGHTS_CONNECTION_STRING = var.app_insights_connection_string
    FUNCTIONS_WORKER_RUNTIME              = "node"
    WEBSITE_VNET_ROUTE_ALL                = "1"
  })

  identity {
    type = "SystemAssigned"
  }
}

# Private endpoint — inbound traffic to each function app via private IP
resource "azurerm_private_endpoint" "func" {
  for_each            = azurerm_linux_function_app.this
  name                = "${each.value.name}-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "${each.value.name}-psc"
    private_connection_resource_id = each.value.id
    subresource_names              = ["sites"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "func-dns-group"
    private_dns_zone_ids = [var.private_dns_zone_id]
  }
}
