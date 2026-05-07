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
  description = "ID of privatelink.mongo.cosmos.azure.com zone"
  type        = string
}

variable "consistency_level" {
  type    = string
  default = "Session"
}

variable "mongo_server_version" {
  type    = string
  default = "6.0"
}

variable "geo_location" {
  type = object({
    location          = string
    failover_priority = number
  })
  default = null
}

variable "databases" {
  description = "Map of database name to throughput and collections"
  type = map(object({
    throughput = optional(number)
    collections = map(object({
      shard_key  = string
      throughput = optional(number)
      indexes    = optional(list(object({
        keys   = list(string)
        unique = bool
      })))
    }))
  }))
  default = {}
}

variable "tags" {
  type    = map(string)
  default = {}
}
