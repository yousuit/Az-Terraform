variable "name" {
  type        = string
  description = "Private DNS zone name (e.g. privatelink.blob.core.windows.net)"
}

variable "resource_group_name" {
  type = string
}

variable "vnet_links" {
  description = "Map of VNet link name => VNet ID"
  type        = map(string)
  default     = {}
}

variable "tags" {
  type    = map(string)
  default = {}
}
