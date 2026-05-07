resource "azurerm_public_ip" "firewall" {
  name                = "${var.name}-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_firewall_policy" "this" {
  name                = "${var.name}-policy"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.sku_tier
  tags                = var.tags

  threat_intelligence_mode = var.threat_intel_mode

  dns {
    proxy_enabled = true
  }
}

resource "azurerm_firewall" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku_name            = "AZFW_VNet"
  sku_tier            = var.sku_tier
  firewall_policy_id  = azurerm_firewall_policy.this.id
  tags                = var.tags

  ip_configuration {
    name                 = "ipconfig"
    subnet_id            = var.subnet_id
    public_ip_address_id = azurerm_public_ip.firewall.id
  }
}

resource "azurerm_firewall_policy_rule_collection_group" "this" {
  name               = "${var.name}-rcg"
  firewall_policy_id = azurerm_firewall_policy.this.id
  priority           = 100

  dynamic "network_rule_collection" {
    for_each = var.network_rules
    content {
      name     = network_rule_collection.value.name
      priority = network_rule_collection.value.priority
      action   = network_rule_collection.value.action

      dynamic "rule" {
        for_each = network_rule_collection.value.rules
        content {
          name                  = rule.value.name
          source_addresses      = rule.value.source_addresses
          destination_addresses = rule.value.destination_addresses
          destination_ports     = rule.value.destination_ports
          protocols             = rule.value.protocols
        }
      }
    }
  }

  dynamic "application_rule_collection" {
    for_each = var.application_rules
    content {
      name     = application_rule_collection.value.name
      priority = application_rule_collection.value.priority
      action   = application_rule_collection.value.action

      dynamic "rule" {
        for_each = application_rule_collection.value.rules
        content {
          name             = rule.value.name
          source_addresses = rule.value.source_addresses
          destination_fqdns = rule.value.target_fqdns

          dynamic "protocols" {
            for_each = rule.value.protocols
            content {
              type = protocols.value.type
              port = protocols.value.port
            }
          }
        }
      }
    }
  }
}
