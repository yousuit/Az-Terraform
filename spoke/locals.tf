locals {
  # ── NAMING CONVENTION ─────────────────────────────────────────
  # Pattern: {type}-{workload}-{org}-{region_short}-{env}-{instance}
  # Examples:
  #   rg-web-qoc-we-prod-001
  #   rg-pdns-qoc-we-prod-001
  #   vnet-qoc-we-prod-001
  #   app-fe-qoc-we-prod-001
  #   func-proc-qoc-we-prod-001
  #   redis-web-qoc-we-prod-001
  #   sql-web-qoc-we-prod-001

  spoke_suffix = "${var.org}-${var.region_short}-${var.environment}-${var.instance}"

  # Resource group names
  spoke_rg_name = "rg-${var.project}-${local.spoke_suffix}"   # rg-web-qoc-we-prod-001
  pdns_rg_name  = "rg-pdns-${local.spoke_suffix}"             # rg-pdns-qoc-we-prod-001

  # Storage account name: no dashes, lowercase, max 24 chars
  # st + org + project + region + env + instance
  storage_name = lower("st${var.org}${var.project}${var.region_short}${var.environment}${var.instance}")

  # DNS zone VNet link map: always link to spoke VNet; optionally also hub VNet
  dns_vnet_links = merge(
    { spoke = module.spoke_vnet.id },
    var.link_dns_to_hub_vnet ? { hub = var.hub_vnet_id } : {}
  )

  common_tags = merge(
    {
      org         = var.org
      environment = var.environment
      project     = var.project
      managed_by  = "terraform"
    },
    var.tags
  )
}
