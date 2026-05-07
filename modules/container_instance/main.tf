resource "azurerm_container_group" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  ip_address_type     = "Private"
  os_type             = var.os_type
  restart_policy      = var.restart_policy
  subnet_ids          = [var.subnet_id]
  tags                = var.tags

  dynamic "container" {
    for_each = var.containers
    content {
      name   = container.value.name
      image  = container.value.image
      cpu    = container.value.cpu
      memory = container.value.memory

      dynamic "ports" {
        for_each = container.value.ports != null ? container.value.ports : []
        content {
          port     = ports.value.port
          protocol = ports.value.protocol
        }
      }

      environment_variables        = container.value.environment_variables
      secure_environment_variables = container.value.secure_environment_variables
    }
  }

  dynamic "image_registry_credential" {
    for_each = var.registry_server != "" ? [1] : []
    content {
      server   = var.registry_server
      username = var.registry_username
      password = var.registry_password
    }
  }

  identity {
    type         = length(var.identity_ids) > 0 ? "UserAssigned" : "SystemAssigned"
    identity_ids = length(var.identity_ids) > 0 ? var.identity_ids : null
  }
}
