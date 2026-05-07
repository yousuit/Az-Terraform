variable "name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "virtual_network_name" {
  type = string
}

variable "address_prefix" {
  type = string
}

variable "nsg_id" {
  type    = string
  default = ""
}

variable "route_table_id" {
  type    = string
  default = ""
}

# Set false on subnets that host private endpoints (disables NSG enforcement on PEs)
variable "private_endpoint_network_policies_enabled" {
  type    = bool
  default = true
}

variable "delegation" {
  description = "Optional service delegation"
  type = object({
    name    = string
    service = string
    actions = list(string)
  })
  default = null
}
