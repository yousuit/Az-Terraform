resource "azurerm_postgresql_flexible_server" "this" {
  name                   = var.name
  resource_group_name    = var.resource_group_name
  location               = var.location
  administrator_login    = var.admin_login
  administrator_password = var.admin_password
  sku_name               = var.sku_name
  version                = var.pg_version
  tags                   = var.tags

  # VNet injection via delegated subnet — private access only
  delegated_subnet_id = var.delegated_subnet_id
  private_dns_zone_id = var.private_dns_zone_id

  storage_mb   = var.storage_mb
  storage_tier = var.storage_tier

  backup_retention_days        = var.backup_retention_days
  geo_redundant_backup_enabled = var.geo_redundant_backup_enabled

  dynamic "high_availability" {
    for_each = var.high_availability_mode != "Disabled" ? [1] : []
    content {
      mode = var.high_availability_mode
    }
  }
}

resource "azurerm_postgresql_flexible_server_database" "this" {
  for_each  = var.databases
  name      = each.key
  server_id = azurerm_postgresql_flexible_server.this.id
  charset   = each.value.charset
  collation = each.value.collation
}
