# ── IDENTITY ──────────────────────────────────────────────────
variable "subscription_id" {
  description = "Spoke Azure subscription ID (dev / staging / prod)"
  type        = string
}
# ── HUB REFERENCES ────────────────────────────────────────────
variable "hub_subscription_id" {
  description = "Hub subscription ID — needed for cross-sub VNet peering and optional DNS linking"
  type        = string
}
variable "hub_vnet_id" {

  description = "Hub VNet resource ID (from: cd hub && terraform output hub_vnet_id)"
  type        = string

}
variable "hub_vnet_name" {

  description = "Hub VNet name (from: terraform output hub_vnet_name)"
  type        = string

}
variable "hub_rg_name" {

  description = "Hub resource group name (from: terraform output hub_rg_name)"
  type        = string

}
variable "hub_firewall_private_ip" {

  description = "Firewall private IP for the UDR default route (from: terraform output firewall_private_ip). Set null when firewall is disabled."
  type        = string
  default     = null

}
variable "hub_keyvault_id" {

  description = "Hub Key Vault resource ID (from: terraform output key_vault_id). Used to grant App Service and AI Foundry managed identities read access."
  type        = string

}
variable "link_dns_to_hub_vnet" {

  description = "When true, all spoke DNS zones are also linked to the hub VNet so management VMs can resolve spoke service hostnames."
  type        = bool
  default     = true

}
# ── NAMING ────────────────────────────────────────────────────
variable "org" {
  description = "Short organisation/project code used in every resource name (e.g. qoc)"
  type        = string
}
variable "environment" {

  type = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Must be: dev | staging | prod"

  }
}

variable "project" {

  description = "Workload/project name used in resource names (e.g. web, api, data)"
  type        = string
  default     = "web"

}
variable "location" {

  type    = string
  default = "westeurope"

}
variable "region_short" {

  description = "2–3 char region code matching location (e.g. we = westeurope, eus = eastus)"
  type        = string
  default     = "we"

}
variable "instance" {

  type    = string
  default = "001"

}
variable "tags" {

  type = map(string)
  default = {

  }
}

# ── SPOKE NETWORKING ──────────────────────────────────────────
variable "spoke_vnet_cidr" {
  type    = string
  default = "10.1.0.0/16"
}
variable "spoke_subnet_cidrs" {
  type = object({
    app_service_vnetint  = string # delegation: Microsoft.Web/serverFarms (outbound VNet integration)
    function_app_vnetint = string # delegation: Microsoft.Web/serverFarms (outbound VNet integration)
    private_endpoints    = string # all private endpoints — PE network policies disabled
    databricks_public    = string # delegation: Microsoft.Databricks/workspaces
    databricks_private   = string # delegation: Microsoft.Databricks/workspaces
    sql_mi               = string # delegation: Microsoft.Sql/managedInstances (module manages NSG+UDR)
    mysql_flexible       = string # delegation: Microsoft.DBforMySQL/flexibleServers (VNet injection)
    postgresql_flexible  = string # delegation: Microsoft.DBforPostgreSQL/flexibleServers (VNet injection)
    container_instances  = string # delegation: Microsoft.ContainerInstance/containerGroups
    ai_foundry_compute   = string # AI Foundry compute clusters and online endpoints
  })
  default = {
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
}

# ── FEATURE FLAGS ─────────────────────────────────────────────
variable "enable_app_service" {
  type    = bool
  default = true
}
variable "enable_function_app" {

  type    = bool
  default = true

}
variable "enable_storage" {

  type    = bool
  default = true

}
variable "enable_redis" {

  type    = bool
  default = true

}
variable "enable_sql_db" {

  type    = bool
  default = true

}
variable "enable_sql_mi" {

  type    = bool
  default = false

}
variable "enable_service_bus" {

  type    = bool
  default = true

}
variable "enable_event_grid" {

  type    = bool
  default = true

}
variable "enable_openai" {

  type    = bool
  default = false

}
variable "enable_search" {

  type    = bool
  default = true

}
variable "enable_speech" {

  type    = bool
  default = true

}
variable "enable_databricks" {

  type    = bool
  default = false

}
variable "enable_mysql_flexible" {

  type    = bool
  default = true

}
variable "enable_postgresql" {

  type    = bool
  default = true

}
variable "enable_cosmosdb_nosql" {

  type    = bool
  default = true

}
variable "enable_cosmosdb_mongo" {

  type    = bool
  default = false

}
variable "enable_ai_vision" {

  type    = bool
  default = true

}
variable "enable_ai_foundry" {

  type    = bool
  default = false

}
variable "enable_bing_search" {

  type    = bool
  default = false

}
variable "enable_container_instance" {

  type    = bool
  default = false

}
# ── WORKLOAD CONFIGS ──────────────────────────────────────────
variable "log_retention_days" {
  type    = number
  default = 30
}
variable "app_service_sku" {

  type    = string
  default = "P1v3"

}
variable "app_service_names" {
  description = "Short names for each App Service web app. Each becomes: app-{name}-{org}-{region}-{env}-{instance}"
  type        = list(string)
  default     = ["fe", "be"]
}

variable "function_app_sku" {

  type    = string
  default = "EP1"

}
variable "function_app_names" {
  description = "Short names for each Function App. Each becomes: func-{name}-{org}-{region}-{env}-{instance}"
  type        = list(string)
  default     = ["proc"]
}

variable "redis_sku" {

  type    = string
  default = "Standard"

}
variable "redis_capacity" {

  type    = number
  default = 1

}
variable "redis_family" {

  type    = string
  default = "C"

}
variable "sql_admin_login" {

  type    = string
  default = "sqladmin"

}
variable "sql_admin_password" {

  type      = string
  sensitive = true
  default   = ""

}
variable "sql_databases" {
  type = map(object({
    sku_name    = string
    max_size_gb = number
  }))
  default = {
    main = { sku_name = "S1", max_size_gb = 32 }
  }
}

variable "sql_mi_sku" {

  type    = string
  default = "GP_Gen5"

}
variable "sql_mi_vcores" {

  type    = number
  default = 4

}
variable "sql_mi_storage_gb" {

  type    = number
  default = 32

}
variable "service_bus_sku" {

  type    = string
  default = "Premium"

}
variable "service_bus_queues" {

  type    = list(string)
  default = []

}
variable "service_bus_topics" {

  type    = list(string)
  default = []

}
variable "openai_location" {

  type    = string
  default = "eastus"

}
variable "openai_deployments" {
  type = map(object({
    model_name    = string
    model_version = string
    sku_name      = optional(string, "Standard") # Standard | GlobalStandard | DataZoneStandard
    capacity      = number
  }))
  default = {}
}

variable "search_sku" {

  type    = string
  default = "standard"

}
# MySQL Flexible — VNet injection (delegated subnet), not a private endpoint
variable "mysql_admin_login" {
  type    = string
  default = "mysqladmin"
}
variable "mysql_admin_password" {

  type      = string
  sensitive = true
  default   = ""

}
variable "mysql_sku_name" {

  type    = string
  default = "Standard_D2ds_v4"

}
variable "mysql_version" {

  type    = string
  default = "8.0.21"

}
variable "mysql_storage_gb" {

  type    = number
  default = 32

}
# PostgreSQL Flexible — VNet injection (delegated subnet), not a private endpoint
variable "postgresql_admin_login" {
  type    = string
  default = "psqladmin"
}
variable "postgresql_admin_password" {

  type      = string
  sensitive = true
  default   = ""

}
variable "postgresql_sku_name" {

  type    = string
  default = "Standard_D2s_v3"

}
variable "postgresql_version" {

  type    = string
  default = "14"

}
variable "postgresql_storage_mb" {

  type    = number
  default = 32768

}
# Container Instance — VNet injection (delegated subnet)
# Must be provided when enable_container_instance = true
variable "container_instance_containers" {
  description = "Container definitions for the Azure Container Instance. Required when enable_container_instance = true."
  type = list(object({
    name   = string
    image  = string
    cpu    = number
    memory = number
    ports = optional(list(object({
      port     = number
      protocol = string
    })))
    environment_variables        = optional(map(string))
    secure_environment_variables = optional(map(string))
  }))
  default = []
}
