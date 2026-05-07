output "id"           { value = azurerm_linux_virtual_machine.agent.id }
output "name"         { value = azurerm_linux_virtual_machine.agent.name }
output "private_ip"   { value = azurerm_network_interface.agent.private_ip_address }
output "principal_id" { value = azurerm_linux_virtual_machine.agent.identity[0].principal_id }
