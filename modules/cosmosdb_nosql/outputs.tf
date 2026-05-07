output "id"           { value = azurerm_cosmosdb_account.this.id }
output "name"         { value = azurerm_cosmosdb_account.this.name }
output "endpoint"     { value = azurerm_cosmosdb_account.this.endpoint }
output "principal_id" { value = azurerm_cosmosdb_account.this.identity[0].principal_id }
output "primary_key" {
  value     = azurerm_cosmosdb_account.this.primary_key
  sensitive = true
}
output "connection_strings" {
  value     = azurerm_cosmosdb_account.this.connection_strings
  sensitive = true
}
