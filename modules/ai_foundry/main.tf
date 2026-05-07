resource "azurerm_machine_learning_workspace" "this" {
  name                    = var.name
  location                = var.location
  resource_group_name     = var.resource_group_name
  application_insights_id = var.application_insights_id
  key_vault_id            = var.key_vault_id
  storage_account_id      = var.storage_account_id
  tags                    = var.tags

  container_registry_id = var.container_registry_id != "" ? var.container_registry_id : null

  identity {
    type = "SystemAssigned"
  }

  managed_network {
    isolation_mode = var.managed_network_isolation_mode
  }
}

# Workspace private endpoint — restricts inbound to the spoke VNet only
resource "azurerm_private_endpoint" "workspace" {
  name                = "${var.name}-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "${var.name}-psc"
    private_connection_resource_id = azurerm_machine_learning_workspace.this.id
    subresource_names              = ["amlworkspace"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name = "foundry-dns-group"
    private_dns_zone_ids = [
      var.private_dns_zone_api_id,
      var.private_dns_zone_notebooks_id,
    ]
  }
}

# Default CPU compute cluster for training / batch inference
resource "azurerm_machine_learning_compute_cluster" "cpu" {
  name                          = "${var.name}-cpu-cluster"
  location                      = var.location
  machine_learning_workspace_id = azurerm_machine_learning_workspace.this.id
  vm_priority                   = "Dedicated"
  vm_size                       = "Standard_DS3_v2"
  subnet_resource_id            = var.compute_subnet_id
  tags                          = var.tags

  scale_settings {
    min_node_count                       = 0
    max_node_count                       = 4
    scale_down_nodes_after_idle_duration = "PT30M"
  }

  identity {
    type = "SystemAssigned"
  }
}
