variable "name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

# Dedicated delegated subnet (Microsoft.DBforPostgreSQL/flexibleServers)
variable "delegated_subnet_id" {
  type = string
}

variable "private_dns_zone_id" {
  description = "ID of privatelink.postgres.database.azure.com zone"
  type        = string
}

variable "admin_login" {
  type = string
}

variable "admin_password" {
  type      = string
  sensitive = true
}

variable "sku_name" {
  type    = string
  default = "GP_Standard_D2ds_v4"
}

variable "pg_version" {
  type    = string
  default = "16"
}

variable "storage_mb" {
  type    = number
  default = 32768
}

variable "storage_tier" {
  type    = string
  default = "P4"
}

variable "backup_retention_days" {
  type    = number
  default = 7
}

variable "geo_redundant_backup_enabled" {
  type    = bool
  default = false
}

variable "high_availability_mode" {
  type    = string
  default = "Disabled"
}

variable "databases" {
  description = "Map of database name to collation"
  type = map(object({
    charset   = string
    collation = string
  }))
  default = {
    main = { charset = "UTF8", collation = "en_US.utf8" }
  }
}

variable "tags" {
  type    = map(string)
  default = {}
}
