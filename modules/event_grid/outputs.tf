output "id"         { value = azurerm_eventgrid_domain.this.id }
output "name"       { value = azurerm_eventgrid_domain.this.name }
output "endpoint"   { value = azurerm_eventgrid_domain.this.endpoint }
output "primary_key" {
  value     = azurerm_eventgrid_domain.this.primary_access_key
  sensitive = true
}
