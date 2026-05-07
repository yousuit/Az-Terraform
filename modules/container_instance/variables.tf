variable "name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

# VNet injection subnet (delegation: Microsoft.ContainerInstance/containerGroups)
variable "subnet_id" {
  type = string
}

variable "os_type" {
  type    = string
  default = "Linux"
}

variable "restart_policy" {
  type    = string
  default = "Always"
}

variable "containers" {
  description = "List of container definitions"
  type = list(object({
    name   = string
    image  = string
    cpu    = number
    memory = number
    ports  = optional(list(object({
      port     = number
      protocol = string
    })))
    environment_variables = optional(map(string))
    secure_environment_variables = optional(map(string))
  }))
}

variable "registry_server" {
  description = "Container registry login server (e.g. myacr.azurecr.io)"
  type        = string
  default     = ""
}

variable "registry_username" {
  type      = string
  default   = ""
  sensitive = true
}

variable "registry_password" {
  type      = string
  default   = ""
  sensitive = true
}

variable "identity_ids" {
  description = "User-assigned managed identity IDs to attach"
  type        = list(string)
  default     = []
}

variable "tags" {
  type    = map(string)
  default = {}
}
