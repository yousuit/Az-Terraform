resource "azurerm_servicebus_namespace" "this" {
  name                          = var.name
  location                      = var.location
  resource_group_name           = var.resource_group_name
  sku                           = var.sku
  capacity                      = var.sku == "Premium" ? var.capacity : 0
  public_network_access_enabled = false
  tags                          = var.tags

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_servicebus_queue" "this" {
  for_each     = toset(var.queues)
  name         = each.key
  namespace_id = azurerm_servicebus_namespace.this.id

  enable_partitioning = false
  max_size_in_megabytes = 1024
}

resource "azurerm_servicebus_topic" "this" {
  for_each     = toset(var.topics)
  name         = each.key
  namespace_id = azurerm_servicebus_namespace.this.id

  enable_partitioning = false
}

resource "azurerm_private_endpoint" "servicebus" {
  name                = "${var.name}-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "${var.name}-psc"
    private_connection_resource_id = azurerm_servicebus_namespace.this.id
    subresource_names              = ["namespace"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "servicebus-dns-group"
    private_dns_zone_ids = [var.private_dns_zone_id]
  }
}
