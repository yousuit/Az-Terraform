variable "profile_name" {
  type = string
}

variable "endpoint_name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "sku" {
  type    = string
  default = "Standard_AzureFrontDoor"
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "origin_host_name" {
  description = "Hostname of the storage static website origin"
  type        = string
}

variable "custom_domain" {
  description = "Optional custom domain (empty string = skip)"
  type        = string
  default     = ""
}
