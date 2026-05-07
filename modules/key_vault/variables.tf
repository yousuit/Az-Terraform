variable "name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "tenant_id" {
  type = string
}

variable "sku_name" {
  type    = string
  default = "standard"
}

variable "soft_delete_retention_days" {
  type    = number
  default = 90
}

variable "purge_protection_enabled" {
  type    = bool
  default = true
}

variable "public_network_access_enabled" {
  description = "Disable after initial deploy; self-hosted agent must reach KV via private endpoint"
  type        = bool
  default     = false
}

variable "network_acls_bypass" {
  type    = list(string)
  default = ["AzureServices"]
}

variable "network_acls_default_action" {
  type    = string
  default = "Deny"
}

variable "network_acls_ip_rules" {
  type    = list(string)
  default = []
}

variable "network_acls_subnet_ids" {
  type    = list(string)
  default = []
}

variable "private_endpoint_subnet_id" {
  type = string
}

variable "private_dns_zone_id" {
  description = "ID of privatelink.vaultcore.azure.net DNS zone"
  type        = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "access_policies" {
  type = map(object({
    key_permissions         = list(string)
    secret_permissions      = list(string)
    certificate_permissions = list(string)
  }))
  default = {}
}
