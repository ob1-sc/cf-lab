resource "nsxt_policy_tier1_gateway" "t1_router_cp" {
  display_name              = var.t1_cp_name
  description               = "Terrafcpvisioned NSX-T Tier-1 Gateway"
  nsx_id                    = var.t1_cp_name
  failover_mode             = "NON_PREEMPTIVE"
  route_advertisement_types = ["TIER1_CONNECTED", "TIER1_STATIC_ROUTES", "TIER1_NAT"]
  edge_cluster_path         = data.nsxt_policy_edge_cluster.edge_cluster.path
  tier0_path                = data.nsxt_policy_tier0_gateway.t0_router.path
}

resource "nsxt_policy_segment" "cp_segment" {
  display_name        = var.cp_segment_name
  description         = "Terraform provisioned NSX-T Segment for Avi VIP"
  connectivity_path   = nsxt_policy_tier1_gateway.t1_router_cp.path
  transport_zone_path = data.nsxt_policy_transport_zone.tz.path
  subnet {
    cidr = "${var.cp_segment_gateway}/${var.cp_segment_ip_addr_mask}"
  }
}