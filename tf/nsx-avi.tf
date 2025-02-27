
data "nsxt_policy_edge_cluster" "edge_cluster" {
  display_name = var.edge_cluster_name
}

data "nsxt_policy_tier0_gateway" "t0_router" {
  display_name = var.t0_router_name
}

data "nsxt_policy_transport_zone" "tz" {
  display_name = var.transport_zone_name
}

resource "nsxt_policy_tier1_gateway" "t1_router_avi_mgmt" {
  display_name              = var.t1_avi_mgmt_name
  description               = "Terraform provisioned NSX-T Tier-1 Gateway"
  nsx_id                    = var.t1_avi_mgmt_name
  failover_mode             = "NON_PREEMPTIVE"
  route_advertisement_types = ["TIER1_CONNECTED", "TIER1_STATIC_ROUTES", "TIER1_NAT"]
  edge_cluster_path         = data.nsxt_policy_edge_cluster.edge_cluster.path
  tier0_path                = data.nsxt_policy_tier0_gateway.t0_router.path
}

resource "nsxt_policy_tier1_gateway" "t1_router_avi_vip" {
  display_name              = var.t1_avi_vip_name
  description               = "Terraform provisioned NSX-T Tier-1 Gateway"
  nsx_id                    = var.t1_avi_vip_name
  failover_mode             = "NON_PREEMPTIVE"
  route_advertisement_types = ["TIER1_CONNECTED", "TIER1_STATIC_ROUTES", "TIER1_NAT"]
  edge_cluster_path         = data.nsxt_policy_edge_cluster.edge_cluster.path
  tier0_path                = data.nsxt_policy_tier0_gateway.t0_router.path
}

resource "nsxt_policy_dhcp_server" "dhcp_server_avi_mgmt" {
  count             = var.avi_mgmt_network_dhcp_enabled ? 1 : 0
  display_name      = "dhcp-server-avi-mgmt-network"
  lease_time        = 86400
  edge_cluster_path = data.nsxt_policy_edge_cluster.edge_cluster.path
  server_addresses  = ["${var.avi_mgmt_dhcp_server_address}/${var.avi_mgmt_network_ip_addr_mask}"]
}

resource "nsxt_policy_segment" "avi_mgmt_segment" {
  depends_on          = [nsxt_policy_dhcp_server.dhcp_server_avi_mgmt]
  display_name        = var.avi_mgmt_segment_name
  description         = "Terraform provisioned NSX-T Segment for Avi Management"
  connectivity_path   = nsxt_policy_tier1_gateway.t1_router_avi_mgmt.path
  transport_zone_path = data.nsxt_policy_transport_zone.tz.path
  dhcp_config_path    = var.avi_mgmt_network_dhcp_enabled ? nsxt_policy_dhcp_server.dhcp_server_avi_mgmt[0].path : null
  subnet {
    cidr        = "${var.avi_mgmt_segment_gateway}/${var.avi_mgmt_network_ip_addr_mask}"
    dhcp_ranges = var.avi_mgmt_network_dhcp_enabled ? ["${var.avi_mgmt_segment_static_ip_begin}-${var.avi_mgmt_segment_static_ip_end}"] : null
    dynamic "dhcp_v4_config" {
      for_each = var.avi_mgmt_network_dhcp_enabled ? [1] : []
      content {
        server_address = "${var.avi_mgmt_dhcp_server_address}/${var.avi_mgmt_network_ip_addr_mask}"
        lease_time     = 86400
      }
    }
  }
}



resource "nsxt_policy_segment" "avi_vip_segment" {
  display_name        = var.avi_vip_segment_name
  description         = "Terraform provisioned NSX-T Segment for Avi VIP"
  connectivity_path   = nsxt_policy_tier1_gateway.t1_router_avi_vip.path
  transport_zone_path = data.nsxt_policy_transport_zone.tz.path
  subnet {
    cidr = "${var.avi_vip_segment_gateway}/${var.avi_vip_segment_ip_addr_mask}"
  }
}

resource "nsxt_policy_group" "gorouters" {
  display_name = "gorouters01"
  description  = "A NS Group for TAS Gorouters created using Terraform"

  # it might be useful to also add a criteria for the foundation name and let BOSH director add a tag
  # with the foundation name to every VM using Identification Tags: https://techdocs.broadcom.com/us/en/vmware-tanzu/platform/tanzu-operations-manager/3-0/tanzu-ops-manager/vsphere-config.html#:~:text=Enter%20your%20comma%2Dseparated%20custom%20Identification%20Tags.
  criteria {
    condition {
      key         = "Tag"
      member_type = "SegmentPort"
      operator    = "EQUALS"
      value       = "router"
    }
  }
  lifecycle {
    ignore_changes = [criteria, conjunction]
  }
}


resource "nsxt_policy_group" "diego_brain" {
  display_name = "diego_brain"
  description  = "A NS Group for TAS Diego Brain VMs"

  # it might be useful to also add a criteria for the foundation name and let BOSH director add a tag
  # with the foundation name to every VM using Identification Tags: https://techdocs.broadcom.com/us/en/vmware-tanzu/platform/tanzu-operations-manager/3-0/tanzu-ops-manager/vsphere-config.html#:~:text=Enter%20your%20comma%2Dseparated%20custom%20Identification%20Tags.
  criteria {
    condition {
      key         = "Tag"
      member_type = "SegmentPort"
      operator    = "EQUALS"
      value       = "control"
    }
  }

  lifecycle {
    ignore_changes = [criteria, conjunction]
  }
}

