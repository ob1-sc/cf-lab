resource "avi_healthmonitor" "tcp_monitor" {
  name         = var.tas_tcp_monitor
  type         = "HEALTH_MONITOR_HTTP"
  monitor_port = 80

  http_monitor {
    http_request       = "GET /health HTTP/1.0"
    http_response_code = ["HTTP_2XX"]
  }
}

resource "avi_vsvip" "tas_tcp" {
  name            = "tas-tcp-vip"
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
      addr = var.tas_tcp_vip
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

resource "avi_pool" "postgres_18000" {
  name                  = "postgres_18000"
  health_monitor_refs   = [avi_healthmonitor.tcp_monitor.id]
  cloud_ref             = avi_cloud.nsxt_cloud.id
  vrf_ref               = avi_vrfcontext.avi_vip_vrf.id
  nsx_securitygroup     = [nsxt_policy_group.tcp_router.path]
  inline_health_monitor = false
  default_server_port   = 18000

  lifecycle {
    # ignore servers as it gets auto-populated from NSX Groups
    ignore_changes = [servers]
  }
}


resource "avi_virtualservice" "postgres_18000" {
  name                    = "postgres-18000"
  enabled                 = true
  vsvip_ref               = avi_vsvip.tas_tcp.id
  cloud_type              = "CLOUD_NSXT"
  cloud_ref               = avi_cloud.nsxt_cloud.id
  vrf_context_ref         = avi_vrfcontext.avi_vip_vrf.id
  application_profile_ref = data.avi_applicationprofile.system_l4_application.id
  services {
    port = 18000
  }
  nsx_securitygroup = [nsxt_policy_group.tcp_router.display_name]
  pool_ref          = avi_pool.postgres_18000.id
  lifecycle {
    ignore_changes = [services, scaleout_ecmp]
  }
}

resource "avi_pool" "postgres_18001" {
  name                  = "postgres_18001"
  health_monitor_refs   = [avi_healthmonitor.tcp_monitor.id]
  cloud_ref             = avi_cloud.nsxt_cloud.id
  vrf_ref               = avi_vrfcontext.avi_vip_vrf.id
  nsx_securitygroup     = [nsxt_policy_group.tcp_router.path]
  inline_health_monitor = false
  default_server_port   = 18001

  lifecycle {
    # ignore servers as it gets auto-populated from NSX Groups
    ignore_changes = [servers]
  }
}

resource "avi_virtualservice" "postgres_ssl" {
  name                    = "tas-postgres-ssl"
  enabled                 = true
  vsvip_ref               = avi_vsvip.tas_tcp.id
  cloud_type              = "CLOUD_NSXT"
  cloud_ref               = avi_cloud.nsxt_cloud.id
  vrf_context_ref         = avi_vrfcontext.avi_vip_vrf.id
  application_profile_ref = data.avi_applicationprofile.system_l4_application.id
  services {
    port = 18001
  }
  nsx_securitygroup = [nsxt_policy_group.tcp_router.display_name]
  pool_ref          = avi_pool.postgres_18001.id
  lifecycle {
    ignore_changes = [services, scaleout_ecmp]
  }
}

resource "avi_pool" "rabbit_17000" {
  name                  = "rabbit-17000"
  health_monitor_refs   = [avi_healthmonitor.tcp_monitor.id]
  cloud_ref             = avi_cloud.nsxt_cloud.id
  vrf_ref               = avi_vrfcontext.avi_vip_vrf.id
  nsx_securitygroup     = [nsxt_policy_group.tcp_router.path]
  inline_health_monitor = false
  default_server_port   = 17000

  lifecycle {
    # ignore servers as it gets auto-populated from NSX Groups
    ignore_changes = [servers]
  }
}

resource "avi_virtualservice" "rabbit_17000" {
  name                    = "rabbit-17000"
  enabled                 = true
  vsvip_ref               = avi_vsvip.tas_tcp.id
  cloud_type              = "CLOUD_NSXT"
  cloud_ref               = avi_cloud.nsxt_cloud.id
  vrf_context_ref         = avi_vrfcontext.avi_vip_vrf.id
  application_profile_ref = data.avi_applicationprofile.system_l4_application.id
  services {
    port = 17000
  }
  nsx_securitygroup = [nsxt_policy_group.tcp_router.display_name]
  pool_ref          = avi_pool.rabbit_17000.id
  lifecycle {
    ignore_changes = [services, scaleout_ecmp]
  }
}

resource "avi_pool" "rabbit_17001" {
  name                  = "rabbit-17001"
  health_monitor_refs   = [avi_healthmonitor.tcp_monitor.id]
  cloud_ref             = avi_cloud.nsxt_cloud.id
  vrf_ref               = avi_vrfcontext.avi_vip_vrf.id
  nsx_securitygroup     = [nsxt_policy_group.tcp_router.path]
  inline_health_monitor = false
  default_server_port   = 17001

  lifecycle {
    # ignore servers as it gets auto-populated from NSX Groups
    ignore_changes = [servers]
  }
}

resource "avi_virtualservice" "rabbit_17001" {
  name                    = "rabbit-17001"
  enabled                 = true
  vsvip_ref               = avi_vsvip.tas_tcp.id
  cloud_type              = "CLOUD_NSXT"
  cloud_ref               = avi_cloud.nsxt_cloud.id
  vrf_context_ref         = avi_vrfcontext.avi_vip_vrf.id
  application_profile_ref = data.avi_applicationprofile.system_l4_application.id
  services {
    port = 17001
  }
  nsx_securitygroup = [nsxt_policy_group.tcp_router.display_name]
  pool_ref          = avi_pool.rabbit_17001.id
  lifecycle {
    ignore_changes = [services, scaleout_ecmp]
  }
}