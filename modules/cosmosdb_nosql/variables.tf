variable "name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "private_endpoint_subnet_id" {
  type = string
}

variable "private_dns_zone_id" {
  description = "ID of privatelink.documents.azure.com zone"
  type        = string
}

variable "consistency_level" {
  type    = string
  default = "Session"
}

variable "max_staleness_prefix" {
  type    = number
  default = 100
}

variable "max_interval_in_seconds" {
  type    = number
  default = 5
}

variable "geo_location" {
  type = object({
    location          = string
    failover_priority = number
  })
  default = null
}

variable "databases" {
  description = "Map of database name to throughput and containers"
  type = map(object({
    throughput = optional(number)
    containers = map(object({
      partition_key_path = string
      throughput         = optional(number)
    }))
  }))
  default = {}
}

variable "tags" {
  type    = map(string)
  default = {}
}
