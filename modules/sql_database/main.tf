resource "azurerm_mssql_server" "this" {
  name                         = var.server_name
  resource_group_name          = var.resource_group_name
  location                     = var.location
  version                      = "12.0"
  administrator_login          = var.admin_login
  administrator_login_password = var.admin_password
  minimum_tls_version          = "1.2"
  tags                         = var.tags

  public_network_access_enabled = false

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_mssql_database" "this" {
  for_each    = var.databases
  name        = each.key
  server_id   = azurerm_mssql_server.this.id
  sku_name    = each.value.sku_name
  max_size_gb = each.value.max_size_gb
  tags        = var.tags

  short_term_retention_policy {
    retention_days           = 7
    backup_interval_in_hours = 12
  }
}

resource "azurerm_private_endpoint" "sql" {
  name                = "${var.server_name}-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "${var.server_name}-psc"
    private_connection_resource_id = azurerm_mssql_server.this.id
    subresource_names              = ["sqlServer"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "sql-dns-group"
    private_dns_zone_ids = [var.private_dns_zone_id]
  }
}
