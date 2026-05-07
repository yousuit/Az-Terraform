variable "name" {
  type        = string
  description = "Base name; '-v7' and '-custom' suffixes are appended automatically"
}

variable "resource_group_name" {
  type = string
}

# Bing Search must be deployed to a specific location (usually global or westus)
variable "location" {
  type    = string
  default = "global"
}

variable "sku_name" {
  type        = string
  description = "Pricing tier for Bing Search v7: F1 (free), S1, S2, S3, S4, S5, S6, S7, S8, S9"
  default     = "S1"
}

variable "custom_search_sku_name" {
  type        = string
  description = "Pricing tier for Bing Custom Search: F0 (free) or S1"
  default     = "S1"
}

variable "tags" {
  type    = map(string)
  default = {}
}
