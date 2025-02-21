provider "avi" {
  avi_controller = var.avi_controller
  avi_username   = var.avi_username
  avi_password   = var.avi_password
  avi_version = "22.1.5"
	avi_tenant     = var.avi_tenant
}

resource "avi_cloudconnectoruser" "nsxt_user" {
  name         = "nsxt-integration-user"
  nsxt_credentials {
    username = var.nsxt_username
    password = var.nsxt_password
  }
}

resource "avi_cloudconnectoruser" "vcenter_user" {
  name = "vcenter-integration-user"
  vcenter_credentials {
    username = var.vcenter_username
    password = var.vcenter_password
  }
}

resource "avi_ipamdnsproviderprofile" "ipam_vip" {
    name = "ipam_vip"
    type = "IPAMDNS_TYPE_INTERNAL"
    internal_profile {
      usable_networks {
        nw_ref = avi_network.avi_vip_segment.id
      }
    }
}
# Create an NSX-T Cloud in Avi
resource "avi_cloud" "nsxt_cloud" {
  name                 = var.avi_cloud_name
  vtype                = "CLOUD_NSXT"
  maintenance_mode = "false"
  obj_name_prefix = "nsx-avi-automated"
  nsxt_configuration {
    nsxt_url     = var.nsxt_host
    nsxt_credentials_ref = avi_cloudconnectoruser.nsxt_user.id

    management_network_config {
      tz_type        = "OVERLAY"
      transport_zone = data.nsxt_policy_transport_zone.tz.path
      overlay_segment {
        tier1_lr_id = nsxt_policy_tier1_gateway.t1_router_avi_mgmt.path
        segment_id  = nsxt_policy_segment.avi_mgmt_segment.path
      }
    }

    data_network_config {
      tz_type        = "OVERLAY"
      transport_zone = data.nsxt_policy_transport_zone.tz.path

      tier1_segment_config {
        segment_config_mode = "TIER1_SEGMENT_MANUAL"
        manual {
          tier1_lrs {
            tier1_lr_id = nsxt_policy_tier1_gateway.t1_router_avi_vip.path
            segment_id  = nsxt_policy_segment.avi_vip_segment.path
          }
        }
      }
    }
  }
}

resource "avi_vcenterserver" "vcenter" {
  name = "vcenter"
  content_lib {
    id = vsphere_content_library.library.id
  }
  vcenter_url             = var.vcenter_host
  vcenter_credentials_ref = avi_cloudconnectoruser.vcenter_user.id
  cloud_ref               = avi_cloud.nsxt_cloud.id
}

# This allows enough time tfor NSX Cloud to auto-populate networks and VRF context
resource "time_sleep" "wait_20_seconds" {
  depends_on = [avi_cloud.nsxt_cloud]
  create_duration = "20s"
}

resource "avi_vrfcontext" "avi_mgmt_vrf" {
  depends_on = [time_sleep.wait_20_seconds]
  name        = nsxt_policy_tier1_gateway.t1_router_avi_mgmt.display_name
  cloud_ref   = avi_cloud.nsxt_cloud.id
  static_routes {
    prefix {
      ip_addr {
        addr = "0.0.0.0"
        type = "V4"
      }
      mask = 0
    }
    next_hop {
      addr = var.avi_mgmt_segment_gateway
      type = "V4"
    }
    route_id = "1"
  }
  attrs {
    key = "tier1path"
    value = nsxt_policy_tier1_gateway.t1_router_avi_mgmt.path
  }
}

resource "avi_vrfcontext" "avi_vip_vrf" {
  depends_on = [time_sleep.wait_20_seconds]
  name        = nsxt_policy_tier1_gateway.t1_router_avi_vip.display_name
  cloud_ref   = avi_cloud.nsxt_cloud.id
  static_routes {
    prefix {
      ip_addr {
        addr = "0.0.0.0"
        type = "V4"
      }
      mask = 0
    }
    next_hop {
      addr = var.avi_vip_segment_gateway
      type = "V4"
    }
    route_id = "1"
  }
  attrs {
    key = "tier1path"
    value = nsxt_policy_tier1_gateway.t1_router_avi_vip.path
  }
}

resource "avi_network" "avi_mgmt_segment" {
  depends_on = [time_sleep.wait_20_seconds]
  name        = var.avi_mgmt_segment_name
  vrf_context_ref = avi_vrfcontext.avi_mgmt_vrf.id
  cloud_ref   = avi_cloud.nsxt_cloud.id
  dhcp_enabled = false
  configured_subnets {
    prefix {
      ip_addr {
        addr = var.avi_mgmt_network_ip_addr
        type = "V4"
      }
      mask = var.avi_mgmt_network_ip_addr_mask
    }
    static_ip_ranges {
      range {
        begin {
          addr = var.avi_mgmt_segment_static_ip_begin
          type = "V4"   
        }
        end {
          addr = var.avi_mgmt_segment_static_ip_end
          type = "V4"
        }
      }
      type = "STATIC_IPS_FOR_VIP_AND_SE"
    }
  }
  attrs {
    key = "segmentid"
    value = nsxt_policy_segment.avi_mgmt_segment.path
  }
  # The below attribute prevents Avi NSX-T Cloud from recreating a new network
}

resource "avi_network" "avi_vip_segment" {
  depends_on = [time_sleep.wait_20_seconds]
  name        = var.avi_vip_segment_name
  vrf_context_ref = avi_vrfcontext.avi_vip_vrf.id
  cloud_ref   = avi_cloud.nsxt_cloud.id
  dhcp_enabled = false
  configured_subnets {
    prefix {
      ip_addr {
        addr = var.avi_vip_segment_ip_addr
        type = "V4"
      }
      mask = var.avi_vip_segment_ip_addr_mask
    }
    static_ip_ranges {
      range {
        begin {
          addr = var.avi_vip_segment_static_ip_begin
          type = "V4"   
        }
        end {
          addr = var.avi_vip_segment_static_ip_end
          type = "V4"
        }
      }
      type = "STATIC_IPS_FOR_VIP_AND_SE"
    }
  }
  # The below attribute prevents Avi NSX-T Cloud from recreating a new network
  attrs {
    key = "segmentid"
    value = nsxt_policy_segment.avi_vip_segment.path
  }
  # attrs {
  #   key = "autocreated"
  #   value = var.avi_cloud_name
  # }
  # attrs {
  #   key = "cloudnetworkmode"
  #   value = "static"
  # }
}

resource "avi_healthmonitor" "web_monitor" {
  name                = var.avi_health_monitor_name
  type                = "HEALTH_MONITOR_HTTP"
  monitor_port        = 8080

  http_monitor {
    http_request = "GET /health HTTP/1.0"
    http_response_code = ["HTTP_2XX"]
  }
}

resource "avi_sslkeyandcertificate" "wildcard_cert" {
  name         = "tas-wildcard-cert"
  key = file("${path.module}/wildcard_cert.key")
  certificate {
    certificate = file("${path.module}/wildcard_cert.crt")
  }
  type= "SSL_CERTIFICATE_TYPE_VIRTUALSERVICE"
}
resource "avi_sslkeyandcertificate" "opsman_root_ca" {
  name         = "opsman_root_ca"
  certificate {
    certificate = var.opsman_ca_cert
  }
  type= "SSL_CERTIFICATE_TYPE_CA"
}


resource "avi_vsvip" "tas_web" {
  name = "tas-web-vip"
  cloud_ref = avi_cloud.nsxt_cloud.id
  vrf_context_ref = avi_vrfcontext.avi_vip_vrf.id
  # tier1_lr = nsxt_policy_tier1_gateway.t1_router_avi_vip.display_name
  vip {
    vip_id                    = "0"
    # auto_allocate_ip          = true
    # avi_allocated_vip         = true
    # auto_allocate_floating_ip = true
    # availability_zone         = var.aws_availability_zone
    # subnet_uuid               = data.aws_subnet.terraform-subnets-0.id

    # TODO: using a static IP here. BUT we actually want to auto_allocate an IP. For this 
    # you need to create an IPAM profile though. But the issue is: to create an IPAM profile, you need
    # to reference a network ref, hence you can only do it AFTER the nsx cloud has been created. 
    # But when creating a cloud, you also need to tell it to use the IPAM profile => chicken-egg problem.
    # posted in https://chat.google.com/room/AAAAq55Tn0s/wJahepY9r5s/wJahepY9r5s?cls=10
    ip_address {
      type = "V4"
      addr = var.tas_gorouter_vip
    }
    subnet {
      ip_addr {
        addr = var.avi_vip_segment_ip_addr
        type = "V4"
      }

      mask = var.avi_vip_segment_ip_addr_mask
    }
  }

}

resource "avi_virtualservice" "dns" {
  name = "tas-web01"
  enabled = true
  vsvip_ref = avi_vsvip.tas_web.id
  cloud_ref = avi_cloud.nsxt_cloud.id
  vrf_context_ref = avi_vrfcontext.avi_vip_vrf.id
  services {
    port = 443
  }
  nsx_securitygroup = [ nsxt_policy_group.gorouters.display_name ]
  
}

variable "avi_controller" {
  description = "Avi Controller IP or Hostname"
  type        = string
}

variable "avi_username" {
  description = "Avi Controller Username"
  type        = string
}

variable "avi_password" {
  description = "Avi Controller Password"
  type        = string
  sensitive   = true
}

variable "avi_tenant" {
  description = "Avi Controller Tenant Name"
  type        = string
  default     = "admin"
}

variable "avi_cloud_name" {}
variable "avi_mgmt_network_ip_addr" {}
variable "avi_mgmt_network_ip_addr_mask" {}
variable "avi_mgmt_segment_gateway" {}
variable "avi_mgmt_segment_static_ip_begin" {}
variable "avi_mgmt_segment_static_ip_end" {}
variable "avi_vip_segment_ip_addr" {}
variable "avi_vip_segment_ip_addr_mask" {}
variable "avi_vip_segment_gateway" {}
variable "avi_vip_segment_static_ip_begin" {}
variable "avi_vip_segment_static_ip_end" {}
variable "avi_health_monitor_name" {}
variable "opsman_ca_cert" {}
variable "tas_gorouter_vip" {}