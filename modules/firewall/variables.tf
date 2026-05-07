variable "name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "sku_tier" {
  type    = string
  default = "Standard"
}

variable "threat_intel_mode" {
  type    = string
  default = "Alert"
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "network_rules" {
  type = list(object({
    name     = string
    priority = number
    action   = string
    rules = list(object({
      name                  = string
      source_addresses      = list(string)
      destination_addresses = list(string)
      destination_ports     = list(string)
      protocols             = list(string)
    }))
  }))
  default = []
}

variable "application_rules" {
  type = list(object({
    name     = string
    priority = number
    action   = string
    rules = list(object({
      name             = string
      source_addresses = list(string)
      target_fqdns     = list(string)
      protocols = list(object({
        type = string
        port = number
      }))
    }))
  }))
  default = []
}
