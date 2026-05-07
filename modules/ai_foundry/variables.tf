variable "name" {
  type        = string
  description = "Azure AI Foundry (Machine Learning) workspace name"
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

# VNet injection subnet for compute clusters / online endpoints
variable "compute_subnet_id" {
  type = string
}

# Inbound private endpoint for the workspace
variable "private_endpoint_subnet_id" {
  type = string
}

variable "private_dns_zone_api_id" {
  description = "ID of privatelink.api.azureml.ms zone"
  type        = string
}

variable "private_dns_zone_notebooks_id" {
  description = "ID of privatelink.notebooks.azure.net zone"
  type        = string
}

# Dependent resources — should be created before the workspace
variable "storage_account_id" {
  type = string
}

variable "key_vault_id" {
  type = string
}

variable "application_insights_id" {
  type = string
}

variable "container_registry_id" {
  type    = string
  default = ""
}

variable "managed_network_isolation_mode" {
  description = "AllowInternetOutbound | AllowOnlyApprovedOutbound | Disabled"
  type        = string
  default     = "AllowInternetOutbound"
}

variable "tags" {
  type    = map(string)
  default = {}
}
