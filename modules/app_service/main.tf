resource "azurerm_service_plan" "this" {
  name                = "${var.name}-asp"
  location            = var.location
  resource_group_name = var.resource_group_name
  os_type             = var.os_type
  sku_name            = var.sku_name
  tags                = var.tags
}

resource "azurerm_linux_web_app" "this" {
  for_each            = { for n in var.app_names : n => n }
  name                = "${var.name}-${each.key}"
  location            = var.location
  resource_group_name = var.resource_group_name
  service_plan_id     = azurerm_service_plan.this.id
  tags                = var.tags

  https_only                    = true
  virtual_network_subnet_id     = var.vnet_integration_subnet_id
  public_network_access_enabled = false

  site_config {
    always_on           = true
    ftps_state          = "Disabled"
    minimum_tls_version = "1.2"
    vnet_route_all_enabled = true

    application_stack {
      node_version = "20-lts"
    }
  }

  app_settings = merge(var.app_settings, {
    APPLICATIONINSIGHTS_CONNECTION_STRING      = var.app_insights_connection_string
    ApplicationInsightsAgent_EXTENSION_VERSION = "~3"
    WEBSITE_VNET_ROUTE_ALL                     = "1"
  })

  identity {
    type = "SystemAssigned"
  }

  logs {
    detailed_error_messages = true
    failed_request_tracing  = true
    http_logs {
      file_system {
        retention_in_days = 7
        retention_in_mb   = 35
      }
    }
  }
}

# Private endpoint — inbound traffic to each app via private IP
resource "azurerm_private_endpoint" "app" {
  for_each            = azurerm_linux_web_app.this
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
    name                 = "app-dns-group"
    private_dns_zone_ids = [var.private_dns_zone_id]
  }
}

# Grant each app read access to Key Vault secrets
resource "azurerm_key_vault_access_policy" "app" {
  for_each = azurerm_linux_web_app.this

  key_vault_id = var.key_vault_id
  tenant_id    = each.value.identity[0].tenant_id
  object_id    = each.value.identity[0].principal_id

  secret_permissions = ["Get", "List"]
}
