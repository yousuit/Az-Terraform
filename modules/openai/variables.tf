variable "name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "sku_name" {
  type    = string
  default = "S0"
}

variable "private_endpoint_subnet_id" {
  type = string
}

variable "private_dns_zone_id" {
  type = string
}

variable "deployments" {
  description = "Map of model deployment name to config"
  type = map(object({
    model_name    = string
    model_version = string
    sku_name      = optional(string, "Standard")   # Standard | GlobalStandard | DataZoneStandard
    capacity      = number
  }))
  default = {}
}

variable "tags" {
  type    = map(string)
  default = {}
}
