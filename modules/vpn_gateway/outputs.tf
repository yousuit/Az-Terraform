output "id"        { value = azurerm_virtual_network_gateway.this.id }
output "name"      { value = azurerm_virtual_network_gateway.this.name }
output "public_ip" { value = azurerm_public_ip.vpn.ip_address }
