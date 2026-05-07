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

variable "tags" {
  type    = map(string)
  default = {}
}

variable "sku_name" {
  type    = string
  default = "WAF_v2"
}

variable "sku_tier" {
  type    = string
  default = "WAF_v2"
}

variable "capacity" {
  type    = number
  default = 2
}

variable "waf_mode" {
  type    = string
  default = "Prevention"
}

variable "waf_rule_set_type" {
  type    = string
  default = "OWASP"
}

variable "waf_rule_set_version" {
  type    = string
  default = "3.2"
}

variable "backend_pools" {
  description = "Map of backend pool name to list of backend FQDNs"
  type        = map(list(string))
  default     = {}
}
