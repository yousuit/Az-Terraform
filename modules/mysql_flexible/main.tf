resource "azurerm_mysql_flexible_server" "this" {
  name                   = var.name
  resource_group_name    = var.resource_group_name
  location               = var.location
  administrator_login    = var.admin_login
  administrator_password = var.admin_password
  sku_name               = var.sku_name
  version                = var.mysql_version
  tags                   = var.tags

  # VNet injection via delegated subnet — private access only
  delegated_subnet_id = var.delegated_subnet_id
  private_dns_zone_id = var.private_dns_zone_id

  storage {
    size_gb = var.storage_size_gb
  }

  backup_retention_days            = var.backup_retention_days
  geo_redundant_backup_enabled = var.geo_redundant_backup_enabled
}

resource "azurerm_mysql_flexible_database" "this" {
  for_each            = var.databases
  name                = each.key
  resource_group_name = var.resource_group_name
  server_name         = azurerm_mysql_flexible_server.this.name
  charset             = each.value.charset
  collation           = each.value.collation
}
