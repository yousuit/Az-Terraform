variable "server_name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "admin_login" {
  type = string
}

variable "admin_password" {
  type      = string
  sensitive = true
}

variable "private_endpoint_subnet_id" {
  type = string
}

variable "private_dns_zone_id" {
  type = string
}

variable "databases" {
  description = "Map of database name to SKU"
  type = map(object({
    sku_name   = string
    max_size_gb = number
  }))
  default = {
    main = {
      sku_name    = "S1"
      max_size_gb = 32
    }
  }
}

variable "tags" {
  type    = map(string)
  default = {}
}
