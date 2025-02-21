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

# Create an NSX-T Cloud in Avi
resource "avi_cloud" "nsxt_cloud" {
  name                 = "nsx-cloud"
  vtype                = "CLOUD_NSXT"
  maintenance_mode = "true"

  nsxt_configuration {
    nsxt_url     = var.nsxt_host
    nsxt_credentials_ref = avi_cloudconnectoruser.nsxt_user.id

    management_network_config {
      tz_type        = "OVERLAY"
      transport_zone = data.nsxt_policy_transport_zone.tz.path
      overlay_segment {
        tier1_lr_id = nsxt_policy_tier1_gateway.t1_router.path
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
            tier1_lr_id = nsxt_policy_tier1_gateway.t1_router.path
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




# variable "nsxt_transport_zone" {
#   description = "Transport Zone ID for NSX-T"
#   type        = string
# }

# variable "nsxt_overlay_segment" {
#   description = "Overlay Segment for Avi Networks"
#   type        = string
# }

# variable "nsxt_tier1_lr" {
#   description = "Tier-1 Logical Router ID"
#   type        = string
# }

# variable "nsxt_site_id" {
#   description = "NSX-T Site ID (for multi-site deployments)"
#   type        = string
#   default     = "default"
# }

# variable "nsxt_mgmt_subnet_ip" {
#   description = "Management Network Subnet IP"
#   type        = string
# }

# variable "nsxt_mgmt_subnet_mask" {
#   description = "Management Network Subnet Mask"
#   type        = number
# }