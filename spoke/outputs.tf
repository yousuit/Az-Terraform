output "spoke_vnet_id"   { value = module.spoke_vnet.id }
output "spoke_rg_name"  { value = module.spoke_rg.name }
output "spoke_vnet_name" { value = module.spoke_vnet.name }

output "app_insights_connection_string" {
  value     = module.monitoring.app_insights_connection_string
  sensitive = true
}

output "app_service_hostnames" {
  value = var.enable_app_service ? module.app_service[0].app_hostnames : {}
}

output "redis_hostname" {
  value = var.enable_redis ? module.redis_cache[0].hostname : null
}

output "sql_server_fqdn" {
  value = var.enable_sql_db ? module.sql_database[0].server_fqdn : null
}

output "service_bus_endpoint" {
  value = var.enable_service_bus ? module.service_bus[0].endpoint : null
}

output "openai_endpoint" {
  value = var.enable_openai ? module.openai[0].endpoint : null
}

output "search_service_name" {
  value = var.enable_search ? module.search_service[0].name : null
}

output "databricks_workspace_url" {
  value = var.enable_databricks ? module.databricks[0].workspace_url : null
}

output "storage_account_name" {
  value = var.enable_storage ? module.storage_account[0].name : null
}
