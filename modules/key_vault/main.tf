data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "this" {
  name                          = var.name
  location                      = var.location
  resource_group_name           = var.resource_group_name
  tenant_id                     = var.tenant_id
  sku_name                      = var.sku_name
  soft_delete_retention_days    = var.soft_delete_retention_days
  purge_protection_enabled      = var.purge_protection_enabled
  enable_rbac_authorization     = false
  public_network_access_enabled = var.public_network_access_enabled
  tags                          = var.tags

  network_acls {
    bypass                     = var.network_acls_bypass
    default_action             = var.network_acls_default_action
    ip_rules                   = var.network_acls_ip_rules
    virtual_network_subnet_ids = var.network_acls_subnet_ids
  }
}

# Deploying service principal gets full access so Terraform can manage secrets
resource "azurerm_key_vault_access_policy" "terraform" {
  key_vault_id = azurerm_key_vault.this.id
  tenant_id    = var.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  key_permissions         = ["Get", "List", "Create", "Delete", "Update", "Purge", "Recover"]
  secret_permissions      = ["Get", "List", "Set", "Delete", "Purge", "Recover"]
  certificate_permissions = ["Get", "List", "Create", "Delete", "Update", "Purge", "Recover"]
}

resource "azurerm_key_vault_access_policy" "custom" {
  for_each = var.access_policies

  key_vault_id = azurerm_key_vault.this.id
  tenant_id    = var.tenant_id
  object_id    = each.key

  key_permissions         = each.value.key_permissions
  secret_permissions      = each.value.secret_permissions
  certificate_permissions = each.value.certificate_permissions
}

resource "azurerm_private_endpoint" "kv" {
  name                = "${var.name}-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "${var.name}-psc"
    private_connection_resource_id = azurerm_key_vault.this.id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "kv-dns-group"
    private_dns_zone_ids = [var.private_dns_zone_id]
  }
}
