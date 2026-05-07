resource "azurerm_public_ip" "appgw" {
  name                = "${var.name}-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_web_application_firewall_policy" "this" {
  name                = "${var.name}-waf-policy"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  policy_settings {
    enabled                     = true
    mode                        = var.waf_mode
    request_body_check          = true
    max_request_body_size_in_kb = 128
    file_upload_limit_in_mb     = 100
  }

  managed_rules {
    managed_rule_set {
      type    = var.waf_rule_set_type
      version = var.waf_rule_set_version
    }
  }
}

locals {
  frontend_port_name         = "https-port"
  frontend_ip_config_name    = "appgw-frontend-ip"
  http_listener_name         = "https-listener"
  default_backend_pool_name  = "default-backend"
  default_backend_http_name  = "default-backend-settings"
  default_routing_rule_name  = "default-rule"
}

resource "azurerm_application_gateway" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
  firewall_policy_id  = azurerm_web_application_firewall_policy.this.id

  sku {
    name     = var.sku_name
    tier     = var.sku_tier
    capacity = var.capacity
  }

  gateway_ip_configuration {
    name      = "appgw-ip-config"
    subnet_id = var.subnet_id
  }

  frontend_port {
    name = local.frontend_port_name
    port = 443
  }

  frontend_port {
    name = "http-port"
    port = 80
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_config_name
    public_ip_address_id = azurerm_public_ip.appgw.id
  }

  backend_address_pool {
    name = local.default_backend_pool_name
  }

  dynamic "backend_address_pool" {
    for_each = var.backend_pools
    content {
      name  = backend_address_pool.key
      fqdns = backend_address_pool.value
    }
  }

  backend_http_settings {
    name                  = local.default_backend_http_name
    cookie_based_affinity = "Disabled"
    port                  = 443
    protocol              = "Https"
    request_timeout       = 30
    pick_host_name_from_backend_address = true
  }

  http_listener {
    name                           = local.http_listener_name
    frontend_ip_configuration_name = local.frontend_ip_config_name
    frontend_port_name             = "http-port"
    protocol                       = "Http"
  }

  # HTTP → HTTPS redirect
  redirect_configuration {
    name                 = "http-to-https"
    redirect_type        = "Permanent"
    target_listener_name = local.http_listener_name
    include_path         = true
    include_query_string = true
  }

  request_routing_rule {
    name               = local.default_routing_rule_name
    rule_type          = "Basic"
    http_listener_name = local.http_listener_name
    priority           = 100

    redirect_configuration_name = "http-to-https"
  }

  waf_configuration {
    enabled          = true
    firewall_mode    = var.waf_mode
    rule_set_type    = var.waf_rule_set_type
    rule_set_version = var.waf_rule_set_version
  }
}
