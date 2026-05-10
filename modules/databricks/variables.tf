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
  default = "premium"
}

variable "vnet_id" {
  type = string
}

variable "public_subnet_name" {
  type = string
}

variable "private_subnet_name" {
  type = string
}

variable "public_subnet_nsg_association_id" {
  description = "Resource ID of azurerm_subnet_network_security_group_association for the public subnet (equals the subnet ID in azurerm 3.x)"
  type        = string
}

variable "private_subnet_nsg_association_id" {
  description = "Resource ID of azurerm_subnet_network_security_group_association for the private subnet (equals the subnet ID in azurerm 3.x)"
  type        = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
