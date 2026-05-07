output "id"           { value = azurerm_search_service.this.id }
output "name"         { value = azurerm_search_service.this.name }
output "principal_id" { value = azurerm_search_service.this.identity[0].principal_id }
output "primary_key" {
  value     = azurerm_search_service.this.primary_key
  sensitive = true
}
