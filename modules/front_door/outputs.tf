output "profile_name" {
  value = azurerm_cdn_frontdoor_profile.this.name
}

output "profile_id" {
  value = azurerm_cdn_frontdoor_profile.this.id
}

output "endpoint_name" {
  value = azurerm_cdn_frontdoor_endpoint.this.name
}

output "endpoint_hostname" {
  value = azurerm_cdn_frontdoor_endpoint.this.host_name
}
