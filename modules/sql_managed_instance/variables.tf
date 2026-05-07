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

variable "admin_login" {
  type = string
}

variable "admin_password" {
  type      = string
  sensitive = true
}

variable "sku_name" {
  type    = string
  default = "GP_Gen5"
}

variable "vcores" {
  type    = number
  default = 4
}

variable "storage_size_in_gb" {
  type    = number
  default = 32
}

variable "license_type" {
  type    = string
  default = "LicenseIncluded"
}

variable "tags" {
  type    = map(string)
  default = {}
}
