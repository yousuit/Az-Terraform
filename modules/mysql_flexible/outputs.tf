output "id"           { value = azurerm_mysql_flexible_server.this.id }
output "name"         { value = azurerm_mysql_flexible_server.this.name }
output "fqdn"         { value = azurerm_mysql_flexible_server.this.fqdn }
output "principal_id" { value = azurerm_mysql_flexible_server.this.identity[0].principal_id }
