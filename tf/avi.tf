resource "avi_systemconfiguration" "controller" {
  uuid                      = "default-uuid"
  welcome_workflow_complete = true
  default_license_tier      = "ENTERPRISE"
  ntp_configuration {
    ntp_servers {
      server {
        type = "DNS"
        addr = "time.google.com"
      }
    }
    ntp_servers {
      server {
        type = "DNS"
        addr = "time1.google.com"
      }
    }
    ntp_servers {
      server {
        type = "DNS"
        addr = "time2.google.com"
      }
    }
    ntp_servers {
      server {
        type = "DNS"
        addr = "time3.google.com"
      }
    }
  }
  dns_configuration {
    server_list {
      addr = "8.8.8.8"
      type = "V4"
    }
    server_list {
      addr = "8.8.4.4"
      type = "V4"
    }
  }
  global_tenant_config {
    se_in_provider_context       = true
    tenant_access_to_provider_se = true
    tenant_vrf                   = false
  }
  email_configuration {
    smtp_type = "SMTP_NONE"
  }

  portal_configuration {
    # TODO: improve that to not allow basic auth => more secure
    allow_basic_authentication = true
  }

  lifecycle {
    ignore_changes = [ssh_ciphers, ssh_hmacs, uuid]
  }
}


resource "null_resource" "add_license" {
  depends_on = [avi_systemconfiguration.controller]

  # Use timestamp to force re-execution
  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = "curl -X PUT -H \"Authorization: Basic ${base64encode("${var.avi_username}:${var.avi_password}")}\" -H \"Content-Type: application/json\" -d '{\"serial_key\":\"${var.avi_license_key}\"}' -k https://${var.avi_controller}/api/license"
  }
}

# This does not work, getting the error "Backup configuration with this Name and Tenant ref already exists."
# Using the REST API call below instead 
# resource "avi_backupconfiguration" "backup_config" {
#   name              = "Backup-Configuration"
#   backup_passphrase = var.avi_password
#   tenant_ref        = var.avi_tenant
#   save_local        = true
# }

data "avi_backupconfiguration" "system_backup_configuration" {
  name = "Backup-Configuration"
}

resource "null_resource" "add_backup_passphrase" {
  depends_on = [avi_systemconfiguration.controller]
  
  # Use timestamp to force re-execution
  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = "bash add_backup_passphrase.sh ${var.avi_tenant} ${var.avi_version} ${var.avi_username} '${var.avi_password}' ${var.avi_controller} ${data.avi_backupconfiguration.system_backup_configuration.uuid} '${var.avi_password}'"
  }
}

resource "avi_cloudconnectoruser" "nsxt_user" {
  depends_on = [avi_systemconfiguration.controller]
  name = var.avi_nsx_usercredentials_name
  nsxt_credentials {
    username = var.nsxt_username
    password = var.nsxt_password
  }
  lifecycle {
    ignore_changes = [nsxt_credentials]
  }
}

resource "avi_cloudconnectoruser" "vcenter_user" {
  depends_on = [avi_systemconfiguration.controller]
  name = var.avi_vcenter_usercredentials_name
  vcenter_credentials {
    username = var.data_plane_vcenter_username
    password = var.data_plane_vcenter_password
  }
  lifecycle {
    ignore_changes = [vcenter_credentials]
  }
}

resource "avi_cloud" "nsxt_cloud" {
  depends_on = [ null_resource.add_license ]
  name             = var.avi_cloud_name
  vtype            = "CLOUD_NSXT"
  # maintenance_mode = "false"
  obj_name_prefix  = var.avi_cloud_obj_name_prefix

  nsxt_configuration {
    nsxt_url             = var.nsxt_host
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
  depends_on = [avi_cloud.nsxt_cloud, avi_cloudconnectoruser.vcenter_user]
  name       = "vcenter"
  content_lib {
    id = vsphere_content_library.library.id
  }
  vcenter_url             = var.data_plane_vcenter_host
  vcenter_credentials_ref = avi_cloudconnectoruser.vcenter_user.id
  cloud_ref               = avi_cloud.nsxt_cloud.id
}

resource "avi_vrfcontext" "avi_mgmt_vrf" {
  count     = var.avi_mgmt_network_dhcp_enabled ? 0 : 1
  name      = nsxt_policy_tier1_gateway.t1_router_avi_mgmt.display_name
  cloud_ref = avi_cloud.nsxt_cloud.id
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
    key   = "tier1path"
    value = nsxt_policy_tier1_gateway.t1_router_avi_mgmt.path
  }
}

resource "avi_vrfcontext" "avi_vip_vrf" {
  name      = nsxt_policy_tier1_gateway.t1_router_avi_vip.display_name
  cloud_ref = avi_cloud.nsxt_cloud.id
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
    key   = "tier1path"
    value = nsxt_policy_tier1_gateway.t1_router_avi_vip.path
  }
}

resource "avi_network" "avi_mgmt_segment" {
  name            = var.avi_mgmt_segment_name
  vrf_context_ref = var.avi_mgmt_network_dhcp_enabled ? null : avi_vrfcontext.avi_mgmt_vrf[0].id
  cloud_ref       = avi_cloud.nsxt_cloud.id
  dhcp_enabled    = var.avi_mgmt_network_dhcp_enabled
  configured_subnets {
    prefix {
      ip_addr {
        addr = var.avi_mgmt_network_ip_addr
        type = "V4"
      }
      mask = var.avi_mgmt_network_ip_addr_mask
    }
    dynamic "static_ip_ranges" {
      for_each = var.avi_mgmt_network_dhcp_enabled ? [] : [1]
      content {
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
  }
  # The below attribute prevents Avi NSX-T Cloud from recreating a new network
  attrs {
    key   = "segmentid"
    value = nsxt_policy_segment.avi_mgmt_segment.path
  }
  attrs {
    key   = "autocreated"
    value = var.avi_cloud_name
  }
  attrs {
    key   = "cloudnetworkmode"
    value = "static"
  }
  lifecycle {
    # always wants to change from true to false on every terraform plan.
    # I assume this is changed at runtime by the NSX Cloud
    ignore_changes = [synced_from_se]
  }
}

resource "avi_network" "avi_vip_segment" {
  name            = var.avi_vip_segment_name
  vrf_context_ref = avi_vrfcontext.avi_vip_vrf.id
  cloud_ref       = avi_cloud.nsxt_cloud.id
  dhcp_enabled    = false
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
    key   = "segmentid"
    value = nsxt_policy_segment.avi_vip_segment.path
  }
  attrs {
    key   = "autocreated"
    value = var.avi_cloud_name
  }
  attrs {
    key   = "cloudnetworkmode"
    value = "static"
  }
  lifecycle {
    # always wants to change from true to false on every terraform plan.
    # I assume this is changed at runtime by the NSX Cloud
    ignore_changes = [synced_from_se]
  }
}

resource "avi_sslkeyandcertificate" "wildcard_cert" {
  name = "tas-wildcard-cert"
  key  = file("${path.module}/tas.key")
  certificate {
    certificate = file("${path.module}/tas.crt")
  }
  type = "SSL_CERTIFICATE_TYPE_VIRTUALSERVICE"

  # because this resource is not idempotent: https://github.com/vmware/terraform-provider-avi/issues/594
  lifecycle {
    ignore_changes = [certificate, ca_certs, key]
  }
}
resource "avi_sslkeyandcertificate" "opsman_root_ca" {
  name = "opsman_root_ca"
  certificate {
    certificate = var.opsman_ca_cert
  }
  type = "SSL_CERTIFICATE_TYPE_CA"

  # because this resource is not idempotent: https://github.com/vmware/terraform-provider-avi/issues/594
  lifecycle {
    ignore_changes = [certificate, ca_certs, key]
  }
}
