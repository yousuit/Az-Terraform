locals {
  # ── NAMING CONVENTION ─────────────────────────────────────────
  # Pattern: {type}-{org}-hub-{region_short}-{environment}-{instance}
  # Examples:
  #   rg-qoc-hub-we-dev-001
  #   rg-pdns-qoc-hub-we-dev-001
  #   azfw-qoc-hub-we-dev-001
  #   agw-qoc-hub-we-dev-001
  #   kv-qoc-hub-we-dev-001

  hub_suffix   = "${var.org}-hub-${var.region_short}-${var.environment}-${var.instance}"

  # Resource group names
  hub_rg_name  = "rg-${local.hub_suffix}"
  pdns_rg_name = "rg-pdns-${local.hub_suffix}"

  common_tags = merge(
    {
      org         = var.org
      environment = var.environment
      workload    = "hub"
      managed_by  = "terraform"
    },
    var.tags
  )
}
