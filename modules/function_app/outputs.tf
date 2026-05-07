output "plan_id"       { value = azurerm_service_plan.this.id }
output "function_ids"  { value = { for k, v in azurerm_linux_function_app.this : k => v.id } }
output "principal_ids" { value = { for k, v in azurerm_linux_function_app.this : k => v.identity[0].principal_id } }
