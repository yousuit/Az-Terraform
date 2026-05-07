# SQL MI requires an NSG and UDR on its dedicated subnet before deployment
resource "azurerm_network_security_group" "sql_mi" {
  name                = "${var.name}-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  security_rule {
    name                       = "AllowManagementInbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "9000-9003"
    source_address_prefix      = "SqlManagement"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowManagementInbound1433"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "1433"
    source_address_prefix      = "SqlManagement"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowManagementOutbound"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "AzureCloud"
  }
}

resource "azurerm_subnet_network_security_group_association" "sql_mi" {
  subnet_id                 = var.subnet_id
  network_security_group_id = azurerm_network_security_group.sql_mi.id
}

resource "azurerm_route_table" "sql_mi" {
  name                          = "${var.name}-rt"
  location                      = var.location
  resource_group_name           = var.resource_group_name
  disable_bgp_route_propagation = false
  tags                          = var.tags

  route {
    name           = "to-internet"
    address_prefix = "0.0.0.0/0"
    next_hop_type  = "Internet"
  }
}

resource "azurerm_subnet_route_table_association" "sql_mi" {
  subnet_id      = var.subnet_id
  route_table_id = azurerm_route_table.sql_mi.id
}

resource "azurerm_mssql_managed_instance" "this" {
  name                         = var.name
  resource_group_name          = var.resource_group_name
  location                     = var.location
  subnet_id                    = var.subnet_id
  administrator_login          = var.admin_login
  administrator_login_password = var.admin_password
  license_type                 = var.license_type
  sku_name                     = var.sku_name
  vcores                       = var.vcores
  storage_size_in_gb           = var.storage_size_in_gb
  tags                         = var.tags

  identity {
    type = "SystemAssigned"
  }

  depends_on = [
    azurerm_subnet_network_security_group_association.sql_mi,
    azurerm_subnet_route_table_association.sql_mi,
  ]
}
