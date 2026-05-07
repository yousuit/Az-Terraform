variable "name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "sku" {
  type    = string
  default = "Premium"
}

variable "admin_enabled" {
  type    = bool
  default = false
}

variable "public_network_access_enabled" {
  type    = bool
  default = false
}

variable "allowed_subnet_ids" {
  type    = list(string)
  default = []
}

variable "private_endpoint_subnet_id" {
  type = string
}

variable "private_dns_zone_id" {
  description = "ID of privatelink.azurecr.io DNS zone"
  type        = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
