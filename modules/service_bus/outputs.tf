output "id"                   { value = azurerm_servicebus_namespace.this.id }
output "name"                 { value = azurerm_servicebus_namespace.this.name }
output "default_primary_key" {
  value     = azurerm_servicebus_namespace.this.default_primary_key
  sensitive = true
}
output "endpoint"             { value = azurerm_servicebus_namespace.this.endpoint }
