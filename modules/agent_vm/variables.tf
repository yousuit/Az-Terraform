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

variable "vm_size" {
  type    = string
  default = "Standard_D4s_v3"
}

variable "admin_username" {
  type = string
}

variable "ssh_public_key" {
  type = string
}

variable "os_disk_size_gb" {
  type    = number
  default = 128
}

variable "tags" {
  type    = map(string)
  default = {}
}
