variable "name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

# Dedicated delegated subnet (Microsoft.DBforMySQL/flexibleServers)
# MySQL Flexible uses VNet injection, not a traditional private endpoint
variable "delegated_subnet_id" {
  type = string
}

variable "private_dns_zone_id" {
  description = "ID of privatelink.mysql.database.azure.com zone"
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

variable "mysql_version" {
  type    = string
  default = "8.0.21"
}

variable "storage_size_gb" {
  type    = number
  default = 20
}

variable "backup_retention_days" {
  type    = number
  default = 7
}

variable "geo_redundant_backup_enabled" {
  type    = bool
  default = false
}

variable "databases" {
  description = "Map of database name to charset/collation"
  type = map(object({
    charset   = string
    collation = string
  }))
  default = {
    main = { charset = "utf8mb4", collation = "utf8mb4_unicode_ci" }
  }
}

variable "tags" {
  type    = map(string)
  default = {}
}
