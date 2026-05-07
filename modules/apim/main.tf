resource "azurerm_api_management" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  publisher_name      = var.publisher_name
  publisher_email     = var.publisher_email
  sku_name            = var.sku_name
  tags                = var.tags

  dynamic "virtual_network_configuration" {
    for_each = var.subnet_id != "" ? [1] : []
    content {
      subnet_id = var.subnet_id
    }
  }

  virtual_network_type = var.subnet_id != "" ? var.virtual_network_type : "None"

  identity {
    type = "SystemAssigned"
  }
}
