# ── PROD SPOKE SUBSCRIPTION ──────────────────────────────────
subscription_id = "00000000-0000-0000-0000-000000000004"   # replace

hub_subscription_id     = "00000000-0000-0000-0000-000000000001"   # replace
hub_vnet_id             = "/subscriptions/.../resourceGroups/rg-qoc-hub-we-001/providers/Microsoft.Network/virtualNetworks/vnet-qoc-hub-we-001"
hub_vnet_name           = "vnet-qoc-hub-we-001"
hub_rg_name             = "rg-qoc-hub-we-001"
hub_firewall_private_ip = "10.0.0.4"    # from hub: terraform output firewall_private_ip
hub_keyvault_id         = "/subscriptions/.../resourceGroups/rg-qoc-hub-we-001/providers/Microsoft.KeyVault/vaults/kv-qoc-hub-we-001"  # from hub: terraform output key_vault_id
link_dns_to_hub_vnet    = true

org          = "qoc"
environment  = "prod"
project      = "web"
location     = "westeurope"
region_short = "we"
instance     = "001"

# Separate CIDR space: prod uses 10.2.x.x
spoke_vnet_cidr = "10.2.0.0/16"
spoke_subnet_cidrs = {
  app_service_vnetint  = "10.2.0.0/24"
  function_app_vnetint = "10.2.1.0/24"
  private_endpoints    = "10.2.2.0/24"
  databricks_public    = "10.2.3.0/24"
  databricks_private   = "10.2.4.0/24"
  sql_mi               = "10.2.5.0/24"
  mysql_flexible       = "10.2.6.0/24"
  postgresql_flexible  = "10.2.7.0/24"
  container_instances  = "10.2.8.0/24"
  ai_foundry_compute   = "10.2.9.0/24"
}

# ── FEATURE FLAGS — all on in prod ───────────────────────────
enable_app_service        = true
enable_function_app       = true
enable_storage            = true
enable_redis              = true
enable_sql_db             = true
enable_sql_mi             = false   # flip to true when SQL MI is required
enable_service_bus        = true
enable_event_grid         = true
enable_openai             = true
enable_search             = true
enable_speech             = true
enable_databricks         = true
enable_mysql_flexible     = true
enable_postgresql         = true
enable_cosmosdb_nosql     = true
enable_cosmosdb_mongo     = false
enable_ai_vision          = true
enable_ai_foundry         = false
enable_bing_search        = false
enable_container_instance = false

# ── SIZING — production-grade SKUs ───────────────────────────
app_service_sku    = "P2v3"
app_service_names  = ["fe", "be"]
function_app_sku   = "EP2"
function_app_names = ["proc", "notifier"]
redis_sku          = "Premium"
redis_family       = "P"
redis_capacity     = 1
service_bus_sku    = "Premium"
search_sku         = "standard"
log_retention_days = 90

sql_admin_login = "sqladmin"
sql_databases   = {
  main  = { sku_name = "S2", max_size_gb = 64 }
  audit = { sku_name = "S1", max_size_gb = 32 }
}

mysql_admin_login  = "mysqladmin"
mysql_sku_name     = "Standard_D4ds_v4"
mysql_version      = "8.0.21"
mysql_storage_gb   = 128

postgresql_admin_login  = "psqladmin"
postgresql_sku_name     = "Standard_D4s_v3"
postgresql_version      = "14"
postgresql_storage_mb   = 131072

openai_location = "eastus"
openai_deployments = {
  gpt4o = {
    model_name    = "gpt-4o"
    model_version = "2024-11-20"
    capacity      = 10
  }
}

tags = {
  cost_center = "engineering"
  owner       = "platform-team"
}
