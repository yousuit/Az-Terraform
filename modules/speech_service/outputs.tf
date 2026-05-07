output "id"       { value = azurerm_cognitive_account.speech.id }
output "name"     { value = azurerm_cognitive_account.speech.name }
output "endpoint" { value = azurerm_cognitive_account.speech.endpoint }
output "primary_key" {
  value     = azurerm_cognitive_account.speech.primary_access_key
  sensitive = true
}
