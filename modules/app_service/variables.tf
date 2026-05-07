variable "name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

# Outbound — VNet integration subnet (delegation: Microsoft.Web/serverFarms)
variable "vnet_integration_subnet_id" {
  type = string
}

# Inbound — private endpoint subnet
variable "private_endpoint_subnet_id" {
  type = string
}

variable "private_dns_zone_id" {
  description = "ID of privatelink.azurewebsites.net DNS zone"
  type        = string
}

variable "os_type" {
  type    = string
  default = "Linux"
}

variable "sku_name" {
  type    = string
  default = "P1v3"
}

variable "app_insights_connection_string" {
  type      = string
  sensitive = true
}

variable "key_vault_id" {
  type = string
}

variable "app_settings" {
  type    = map(string)
  default = {}
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "app_names" {
  description = "List of App Service names to create under this plan"
  type        = list(string)
  default     = ["app"]
}
