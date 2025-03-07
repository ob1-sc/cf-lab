resource "avi_healthmonitor" "web_monitor" {
  name         = var.tas_web_monitor
  type         = "HEALTH_MONITOR_HTTP"
  monitor_port = 8080

  http_monitor {
    http_request       = "GET /health HTTP/1.0"
    http_response_code = ["HTTP_2XX"]
  }
}

resource "avi_healthmonitor" "cf_ssh_monitor" {
  name         = var.tas_ssh_monitor
  type         = "HEALTH_MONITOR_TCP"
  monitor_port = 2222
}

resource "avi_vsvip" "tas_web" {
  name            = "tas-web-vip"
  cloud_ref       = avi_cloud.nsxt_cloud.id
  vrf_context_ref = avi_vrfcontext.avi_vip_vrf.id
  vip {
    vip_id = "0"

    # using a static IP here as auto_allocate an IP is not possible: For this 
    # you need to create an IPAM profile and refer it in the cloud. But the issue is: to create an IPAM profile, you need
    # to reference a network, hence you can only do it AFTER the NSX cloud has been created. 
    # But when creating a cloud, you also need to tell it to use the IPAM profile => chicken-egg problem.
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

resource "avi_pool" "tas_web_pool" {
  name                  = "tas-web-pool01"
  health_monitor_refs   = [avi_healthmonitor.web_monitor.id]
  cloud_ref             = avi_cloud.nsxt_cloud.id
  vrf_ref               = avi_vrfcontext.avi_vip_vrf.id
  nsx_securitygroup     = [nsxt_policy_group.gorouters.path]
  inline_health_monitor = false

  lifecycle {
    # ignore servers as it gets auto-populated from NSX Groups
    ignore_changes = [servers]
  }
}

resource "avi_virtualservice" "tas" {
  name                    = "tas-web01"
  enabled                 = true
  vsvip_ref               = avi_vsvip.tas_web.id
  cloud_type              = "CLOUD_NSXT"
  cloud_ref               = avi_cloud.nsxt_cloud.id
  vrf_context_ref         = avi_vrfcontext.avi_vip_vrf.id
  application_profile_ref = data.avi_applicationprofile.system_secure_http.id
  services {
    port       = 443
    enable_ssl = true
  }
  ssl_key_and_certificate_refs = [avi_sslkeyandcertificate.wildcard_cert.id]
  nsx_securitygroup            = [nsxt_policy_group.gorouters.display_name]
  pool_ref                     = avi_pool.tas_web_pool.id
  lifecycle {
    ignore_changes = [services, scaleout_ecmp]
  }
}

resource "avi_pool" "tas_ssh_pool" {
  name                  = "tas-ssh-pool01"
  health_monitor_refs   = [avi_healthmonitor.cf_ssh_monitor.id]
  cloud_ref             = avi_cloud.nsxt_cloud.id
  vrf_ref               = avi_vrfcontext.avi_vip_vrf.id
  nsx_securitygroup     = [nsxt_policy_group.diego_brain.path]
  inline_health_monitor = false
  default_server_port   = 2222

  lifecycle {
    # ignore servers as it gets auto-populated from NSX Groups
    ignore_changes = [servers]
  }
}

resource "avi_virtualservice" "cf_ssh" {
  name                    = "tas-ssh01"
  enabled                 = true
  vsvip_ref               = avi_vsvip.tas_web.id
  cloud_type              = "CLOUD_NSXT"
  cloud_ref               = avi_cloud.nsxt_cloud.id
  vrf_context_ref         = avi_vrfcontext.avi_vip_vrf.id
  application_profile_ref = data.avi_applicationprofile.system_l4_application.id
  services {
    port = 2222
  }
  nsx_securitygroup = [nsxt_policy_group.diego_brain.display_name]
  pool_ref          = avi_pool.tas_ssh_pool.id
  lifecycle {
    ignore_changes = [services, scaleout_ecmp]
  }
}
