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

variable "sku" {
  type    = string
  default = "VpnGw1"
}

variable "generation" {
  type    = string
  default = "Generation1"
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "local_network_gateways" {
  description = "On-premises gateways to connect to via IPsec"
  type = list(object({
    name            = string
    gateway_address = string
    address_spaces  = list(string)
    shared_key      = string
  }))
  default = []
}
