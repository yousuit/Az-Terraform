resource "azurerm_subnet" "this" {
  name                                          = var.name
  resource_group_name                           = var.resource_group_name
  virtual_network_name                          = var.virtual_network_name
  address_prefixes                              = [var.address_prefix]
  private_endpoint_network_policies_enabled     = var.private_endpoint_network_policies_enabled

  dynamic "delegation" {
    for_each = var.delegation != null ? [var.delegation] : []
    content {
      name = delegation.value.name
      service_delegation {
        name    = delegation.value.service
        actions = delegation.value.actions
      }
    }
  }
}

resource "azurerm_subnet_network_security_group_association" "this" {
  count                     = var.nsg_id != "" ? 1 : 0
  subnet_id                 = azurerm_subnet.this.id
  network_security_group_id = var.nsg_id
}

resource "azurerm_subnet_route_table_association" "this" {
  count          = var.route_table_id != "" ? 1 : 0
  subnet_id      = azurerm_subnet.this.id
  route_table_id = var.route_table_id
}
