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

variable "storage_account_name" {
  type = string
}

variable "storage_account_access_key" {
  type      = string
  sensitive = true
}

variable "sku_name" {
  type    = string
  default = "EP1"
}

variable "app_insights_connection_string" {
  type      = string
  sensitive = true
}

variable "app_settings" {
  type    = map(string)
  default = {}
}

variable "function_names" {
  type    = list(string)
  default = ["func"]
}

variable "tags" {
  type    = map(string)
  default = {}
}
