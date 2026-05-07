variable "name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "account_tier" {
  type    = string
  default = "Standard"
}

variable "replication_type" {
  type    = string
  default = "LRS"
}

variable "private_endpoint_subnet_id" {
  type = string
}

variable "private_dns_zone_blob_id" {
  type = string
}

variable "private_dns_zone_file_id" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
