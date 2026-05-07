# Bing Search v7 — web/image/video/news search APIs
# Note: Bing Search is internet-facing; VNet/private endpoints are not supported
resource "azurerm_cognitive_account" "bing_search_v7" {
  name                = "${var.name}-v7"
  location            = var.location
  resource_group_name = var.resource_group_name
  kind                = "Bing.Search.v7"
  sku_name            = var.sku_name
  tags                = var.tags
}

# Bing Custom Search — search over your own defined corpus
resource "azurerm_cognitive_account" "bing_custom_search" {
  name                = "${var.name}-custom"
  location            = var.location
  resource_group_name = var.resource_group_name
  kind                = "Bing.CustomSearch"
  sku_name            = var.custom_search_sku_name
  tags                = var.tags
}
