output "plan_id"          { value = azurerm_service_plan.this.id }
output "app_ids"          { value = { for k, v in azurerm_linux_web_app.this : k => v.id } }
output "app_hostnames"    { value = { for k, v in azurerm_linux_web_app.this : k => v.default_hostname } }
output "principal_ids"    { value = { for k, v in azurerm_linux_web_app.this : k => v.identity[0].principal_id } }
