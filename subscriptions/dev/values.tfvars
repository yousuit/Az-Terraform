# ── DEV SPOKE SUBSCRIPTION ───────────────────────────────────
# Used by: spoke/ root
# Run 'terraform output' from hub/ and fill in the hub_* values below
# Commands:
#   az login
#   az account set --subscription <subscription_id>
#   terraform init  -backend-config="../subscriptions/dev/backend.tfvars"
#   terraform apply -var-file="../subscriptions/dev/values.tfvars" \
#                   -var="sql_admin_password=<secret>"

subscription_id = "00000000-0000-0000-0000-000000000002"   # replace — dev subscription

# ── HUB REFERENCES (from: cd hub && terraform output) ────────
hub_subscription_id     = "00000000-0000-0000-0000-000000000001"   # replace
hub_vnet_id             = "/subscriptions/.../resourceGroups/rg-qoc-hub-we-001/providers/Microsoft.Network/virtualNetworks/vnet-qoc-hub-we-001"
hub_vnet_name           = "vnet-qoc-hub-we-001"
hub_rg_name             = "rg-qoc-hub-we-001"
hub_firewall_private_ip = "10.0.0.4"    # from hub: terraform output firewall_private_ip
hub_keyvault_id         = "/subscriptions/.../resourceGroups/rg-qoc-hub-we-001/providers/Microsoft.KeyVault/vaults/kv-qoc-hub-we-001"  # from hub: terraform output key_vault_id
link_dns_to_hub_vnet    = true

# ── NAMING ───────────────────────────────────────────────────
# All spoke resources: {type}-{workload}-{org}-{region_short}-{env}-{instance}
# Examples: rg-web-qoc-we-dev-001 / app-fe-qoc-we-dev-001 / sql-web-qoc-we-dev-001
org          = "qoc"
environment  = "dev"
project      = "web"
location     = "westeurope"
region_short = "we"
instance     = "001"

# ── SPOKE NETWORKING ─────────────────────────────────────────
spoke_vnet_cidr = "10.1.0.0/16"
spoke_subnet_cidrs = {
  app_service_vnetint  = "10.1.0.0/24"
  function_app_vnetint = "10.1.1.0/24"
  private_endpoints    = "10.1.2.0/24"
  databricks_public    = "10.1.3.0/24"
  databricks_private   = "10.1.4.0/24"
  sql_mi               = "10.1.5.0/24"
  mysql_flexible       = "10.1.6.0/24"
  postgresql_flexible  = "10.1.7.0/24"
  container_instances  = "10.1.8.0/24"
  ai_foundry_compute   = "10.1.9.0/24"
}

# ── FEATURE FLAGS — scale down in dev ────────────────────────
enable_app_service        = true
enable_function_app       = true
enable_storage            = true
enable_redis              = true
enable_sql_db             = true
enable_sql_mi             = false
enable_service_bus        = true
enable_event_grid         = true
enable_openai             = false
enable_search             = true
enable_speech             = true
enable_databricks         = false
enable_mysql_flexible     = true
enable_postgresql         = true
enable_cosmosdb_nosql     = true
enable_cosmosdb_mongo     = false
enable_ai_vision          = true
enable_ai_foundry         = false
enable_bing_search        = false
enable_container_instance = false

# ── SIZING — smaller SKUs for dev ────────────────────────────
app_service_sku    = "P1v3"
app_service_names  = ["fe", "be"]

function_app_sku   = "EP1"
function_app_names = ["proc"]

redis_sku      = "Standard"
redis_family   = "C"
redis_capacity = 1

service_bus_sku = "Premium"
search_sku      = "standard"
log_retention_days = 30

sql_admin_login = "sqladmin"
# sql_admin_password — pass via -var flag

sql_databases = {
  main = { sku_name = "S1", max_size_gb = 32 }
}

mysql_admin_login    = "mysqladmin"
mysql_sku_name       = "Standard_D2ds_v4"
mysql_version        = "8.0.21"
mysql_storage_gb     = 32

postgresql_admin_login    = "psqladmin"
postgresql_sku_name       = "Standard_D2s_v3"
postgresql_version        = "14"
postgresql_storage_mb     = 32768

tags = {
  cost_center = "engineering"
  owner       = "dev-team"
}
