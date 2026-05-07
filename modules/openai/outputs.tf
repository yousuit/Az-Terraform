output "id"           { value = azurerm_cognitive_account.openai.id }
output "name"         { value = azurerm_cognitive_account.openai.name }
output "endpoint"     { value = azurerm_cognitive_account.openai.endpoint }
output "principal_id" { value = azurerm_cognitive_account.openai.identity[0].principal_id }
output "primary_key" {
  value     = azurerm_cognitive_account.openai.primary_access_key
  sensitive = true
}
