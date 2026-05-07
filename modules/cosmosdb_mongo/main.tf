resource "azurerm_cosmosdb_account" "this" {
  name                          = var.name
  location                      = var.location
  resource_group_name           = var.resource_group_name
  offer_type                    = "Standard"
  kind                          = "MongoDB"
  mongo_server_version          = var.mongo_server_version
  public_network_access_enabled = false
  tags                          = var.tags

  consistency_policy {
    consistency_level = var.consistency_level
  }

  geo_location {
    location          = var.geo_location != null ? var.geo_location.location : var.location
    failover_priority = var.geo_location != null ? var.geo_location.failover_priority : 0
  }

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_cosmosdb_mongo_database" "this" {
  for_each            = var.databases
  name                = each.key
  resource_group_name = var.resource_group_name
  account_name        = azurerm_cosmosdb_account.this.name
  throughput          = each.value.throughput
}

resource "azurerm_cosmosdb_mongo_collection" "this" {
  for_each = merge([
    for db_name, db in var.databases : {
      for col_name, col in db.collections :
      "${db_name}/${col_name}" => merge(col, { database = db_name })
    }
  ]...)

  name                = split("/", each.key)[1]
  resource_group_name = var.resource_group_name
  account_name        = azurerm_cosmosdb_account.this.name
  database_name       = each.value.database
  shard_key           = each.value.shard_key
  throughput          = each.value.throughput

  dynamic "index" {
    for_each = each.value.indexes != null ? each.value.indexes : []
    content {
      keys   = index.value.keys
      unique = index.value.unique
    }
  }

  depends_on = [azurerm_cosmosdb_mongo_database.this]
}

resource "azurerm_private_endpoint" "cosmos_mongo" {
  name                = "${var.name}-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "${var.name}-psc"
    private_connection_resource_id = azurerm_cosmosdb_account.this.id
    subresource_names              = ["MongoDB"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "cosmos-mongo-dns-group"
    private_dns_zone_ids = [var.private_dns_zone_id]
  }
}
