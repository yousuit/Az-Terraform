# ── IDENTITY ─────────────────────────────────────────────────
output "hub_subscription_id" {
  description = "Hub subscription ID — pass to spoke as hub_subscription_id"
  value       = var.subscription_id
}

# ── NETWORKING ────────────────────────────────────────────────
output "hub_vnet_id" {
  description = "Hub VNet resource ID — pass to spoke as hub_vnet_id"
  value       = module.hub_vnet.id
}

output "hub_vnet_name" {
  description = "Hub VNet name — used in peering resource names"
  value       = module.hub_vnet.name
}

output "hub_rg_name" {
  description = "Hub resource group name — pass to spoke as hub_rg_name"
  value       = module.hub_rg.name
}

output "hub_mgmt_subnet_id" {
  description = "Management subnet ID — used in KV/ACR network ACLs"
  value       = module.snet_mgmt.id
}

output "firewall_private_ip" {
  description = "Azure Firewall private IP — pass to spoke as hub_firewall_private_ip for the UDR"
  value       = var.enable_firewall ? module.firewall[0].private_ip : null
}

output "app_gateway_public_ip" {
  value = var.enable_app_gateway ? module.application_gateway[0].public_ip : null
}

output "apim_gateway_url" {
  value = var.enable_apim ? module.apim[0].gateway_url : null
}

# ── HUB SHARED SERVICES ───────────────────────────────────────
output "key_vault_id" {
  description = "Hub Key Vault resource ID — pass to spoke as hub_keyvault_id"
  value       = module.key_vault.id
}

output "key_vault_uri" {
  value = module.key_vault.vault_uri
}

output "acr_id" {
  description = "Hub ACR resource ID — pass to spoke as hub_acr_id"
  value       = module.container_registry.id
}

output "acr_login_server" {
  description = "Hub ACR login server — used by CI/CD to push/pull images"
  value       = module.container_registry.login_server
}

# ── HUB DNS ZONE IDs (pass to spoke for PE registration) ─────
output "dns_keyvault_zone_id" { value = module.dns_keyvault.id }
output "dns_acr_zone_id"      { value = module.dns_acr.id }
