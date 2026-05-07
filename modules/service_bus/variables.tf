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
  default = "Premium"
}

variable "capacity" {
  type    = number
  default = 1
}

variable "private_endpoint_subnet_id" {
  type = string
}

variable "private_dns_zone_id" {
  type = string
}

variable "queues" {
  type    = list(string)
  default = []
}

variable "topics" {
  type    = list(string)
  default = []
}

variable "tags" {
  type    = map(string)
  default = {}
}
