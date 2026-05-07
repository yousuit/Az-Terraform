output "bing_search_v7_id"       { value = azurerm_cognitive_account.bing_search_v7.id }
output "bing_search_v7_endpoint" { value = azurerm_cognitive_account.bing_search_v7.endpoint }
output "bing_search_v7_key" {
  value     = azurerm_cognitive_account.bing_search_v7.primary_access_key
  sensitive = true
}

output "bing_custom_search_id"       { value = azurerm_cognitive_account.bing_custom_search.id }
output "bing_custom_search_endpoint" { value = azurerm_cognitive_account.bing_custom_search.endpoint }
output "bing_custom_search_key" {
  value     = azurerm_cognitive_account.bing_custom_search.primary_access_key
  sensitive = true
}
