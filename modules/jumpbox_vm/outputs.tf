output "id"           { value = azurerm_windows_virtual_machine.jumpbox.id }
output "name"         { value = azurerm_windows_virtual_machine.jumpbox.name }
output "private_ip"   { value = azurerm_network_interface.jumpbox.private_ip_address }
output "principal_id" { value = azurerm_windows_virtual_machine.jumpbox.identity[0].principal_id }
