resource "azurerm_cosmosdb_account" "this" {
  name                          = var.name
  location                      = var.location
  resource_group_name           = var.resource_group_name
  offer_type                    = "Standard"
  kind                          = "GlobalDocumentDB"
  public_network_access_enabled = false
  tags                          = var.tags

  consistency_policy {
    consistency_level       = var.consistency_level
    max_staleness_prefix    = var.max_staleness_prefix
    max_interval_in_seconds = var.max_interval_in_seconds
  }

  geo_location {
    location          = var.geo_location != null ? var.geo_location.location : var.location
    failover_priority = var.geo_location != null ? var.geo_location.failover_priority : 0
  }

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_cosmosdb_sql_database" "this" {
  for_each            = var.databases
  name                = each.key
  resource_group_name = var.resource_group_name
  account_name        = azurerm_cosmosdb_account.this.name
  throughput          = each.value.throughput
}

resource "azurerm_cosmosdb_sql_container" "this" {
  for_each = merge([
    for db_name, db in var.databases : {
      for container_name, container in db.containers :
      "${db_name}/${container_name}" => merge(container, { database = db_name })
    }
  ]...)

  name                = split("/", each.key)[1]
  resource_group_name = var.resource_group_name
  account_name        = azurerm_cosmosdb_account.this.name
  database_name       = each.value.database
  partition_key_path  = each.value.partition_key_path
  throughput          = each.value.throughput

  depends_on = [azurerm_cosmosdb_sql_database.this]
}

resource "azurerm_private_endpoint" "cosmos_nosql" {
  name                = "${var.name}-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "${var.name}-psc"
    private_connection_resource_id = azurerm_cosmosdb_account.this.id
    subresource_names              = ["Sql"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "cosmos-nosql-dns-group"
    private_dns_zone_ids = [var.private_dns_zone_id]
  }
}
