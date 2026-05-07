output "id"             { value = azurerm_container_registry.this.id }
output "name"           { value = azurerm_container_registry.this.name }
output "login_server"   { value = azurerm_container_registry.this.login_server }
output "principal_id"   { value = azurerm_container_registry.this.identity[0].principal_id }
