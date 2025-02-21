terraform {
  required_providers {
    nsxt = {
      source  = "vmware/nsxt"
      version = "~> 3.0"
    }
    avi = {
      source  = "vmware/avi"
      version = "22.1.5"
    }
    vsphere = {
      source = "hashicorp/vsphere"
    }
  }
}

provider "nsxt" {
  host                 = var.nsxt_host
  username             = var.nsxt_username
  password             = var.nsxt_password
  allow_unverified_ssl = true
}

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

resource "nsxt_policy_segment" "avi_mgmt_segment" {
  display_name        = var.avi_mgmt_segment_name
  description         = "Terraform provisioned NSX-T Segment for Avi Management"
  connectivity_path   = nsxt_policy_tier1_gateway.t1_router_avi_mgmt.path
  transport_zone_path = data.nsxt_policy_transport_zone.tz.path
  subnet {
    cidr = "${var.avi_mgmt_segment_gateway}/${var.avi_mgmt_network_ip_addr_mask}"
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
}

variable "nsxt_host" {}
variable "nsxt_username" {}
variable "nsxt_password" {}
variable "t1_avi_mgmt_name" {}
variable "t1_avi_vip_name" {}
variable "edge_cluster_name" {}
variable "t0_router_name" {}
variable "transport_zone_name" {}
variable "avi_mgmt_segment_name" {}
variable "avi_vip_segment_name" {}
