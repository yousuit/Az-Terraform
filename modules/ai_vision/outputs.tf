output "id"           { value = azurerm_cognitive_account.vision.id }
output "name"         { value = azurerm_cognitive_account.vision.name }
output "endpoint"     { value = azurerm_cognitive_account.vision.endpoint }
output "principal_id" { value = azurerm_cognitive_account.vision.identity[0].principal_id }
output "primary_key" {
  value     = azurerm_cognitive_account.vision.primary_access_key
  sensitive = true
}
