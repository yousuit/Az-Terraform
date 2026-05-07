resource "azurerm_public_ip" "vpn" {
  name                = "${var.name}-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_virtual_network_gateway" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  type                = "Vpn"
  vpn_type            = "RouteBased"
  sku                 = var.sku
  generation          = var.generation
  enable_bgp          = false
  tags                = var.tags

  ip_configuration {
    name                          = "ipconfig"
    public_ip_address_id          = azurerm_public_ip.vpn.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = var.subnet_id
  }
}

resource "azurerm_local_network_gateway" "this" {
  for_each            = { for gw in var.local_network_gateways : gw.name => gw }
  name                = each.value.name
  location            = var.location
  resource_group_name = var.resource_group_name
  gateway_address     = each.value.gateway_address
  address_space       = each.value.address_spaces
  tags                = var.tags
}

resource "azurerm_virtual_network_gateway_connection" "this" {
  for_each                   = { for gw in var.local_network_gateways : gw.name => gw }
  name                       = "${var.name}-to-${each.value.name}"
  location                   = var.location
  resource_group_name        = var.resource_group_name
  type                       = "IPsec"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.this.id
  local_network_gateway_id   = azurerm_local_network_gateway.this[each.key].id
  shared_key                 = each.value.shared_key
  tags                       = var.tags
}
