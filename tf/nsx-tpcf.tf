# data "nsxt_policy_edge_cluster" "edge_cluster" {
#   display_name = var.edge_cluster_name
# }

# data "nsxt_policy_tier0_gateway" "t0_router" {
#   display_name = var.t0_router_name
# }

# data "nsxt_policy_transport_zone" "tz" {
#   display_name = var.transport_zone_name
# }

resource "nsxt_policy_tier1_gateway" "t1_router_tpcf" {
  display_name              = var.t1_tpcf_name
  description               = "Terraform provisioned NSX-T Tier-1 Gateway"
  nsx_id                    = var.t1_tpcf_name
  failover_mode             = "NON_PREEMPTIVE"
  route_advertisement_types = ["TIER1_CONNECTED", "TIER1_STATIC_ROUTES", "TIER1_NAT"]
  edge_cluster_path         = data.nsxt_policy_edge_cluster.edge_cluster.path
  tier0_path                = data.nsxt_policy_tier0_gateway.t0_router.path
}

resource "nsxt_policy_segment" "tpcf_infra_segment" {
  display_name        = var.tpcf_infra_segment_name
  description         = "Terraform provisioned NSX-T Segment for TPCF Infra"
  connectivity_path   = nsxt_policy_tier1_gateway.t1_router_tpcf.path
  transport_zone_path = data.nsxt_policy_transport_zone.tz.path
  subnet {
    cidr        = "${var.tpcf_infra_segment_gateway}/${var.tpcf_infra_segment_ip_addr_mask}"
  }
}

resource "nsxt_policy_segment" "tpcf_deployment_segment" {
  display_name        = var.tpcf_deployment_segment_name
  description         = "Terraform provisioned NSX-T Segment for TPCF Deployment"
  connectivity_path   = nsxt_policy_tier1_gateway.t1_router_tpcf.path
  transport_zone_path = data.nsxt_policy_transport_zone.tz.path
  subnet {
    cidr        = "${var.tpcf_deployment_segment_gateway}/${var.tpcf_deployment_segment_ip_addr_mask}"
  }
}

