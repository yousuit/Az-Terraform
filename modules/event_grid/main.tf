resource "azurerm_eventgrid_domain" "this" {
  name                          = var.name
  location                      = var.location
  resource_group_name           = var.resource_group_name
  public_network_access_enabled = false
  tags                          = var.tags

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_private_endpoint" "eventgrid" {
  name                = "${var.name}-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "${var.name}-psc"
    private_connection_resource_id = azurerm_eventgrid_domain.this.id
    subresource_names              = ["domain"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "eventgrid-dns-group"
    private_dns_zone_ids = [var.private_dns_zone_id]
  }
}
