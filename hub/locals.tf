locals {
  # ── NAMING CONVENTION ─────────────────────────────────────────
  # Pattern: {type}-{org}-hub-{region_short}-{instance}
  # Examples:
  #   rg-qoc-hub-we-001
  #   rg-pdns-qoc-hub-we-001
  #   azfw-qoc-hub-we-001
  #   agw-qoc-hub-we-001
  #   kv-qoc-hub-we-001

  hub_suffix = "${var.org}-hub-${var.region_short}-${var.instance}"

  # Resource group names
  hub_rg_name  = "rg-${local.hub_suffix}"
  pdns_rg_name = "rg-pdns-${local.hub_suffix}"

  common_tags = merge(
    {
      org        = var.org
      workload   = "hub"
      managed_by = "terraform"
    },
    var.tags
  )
}
