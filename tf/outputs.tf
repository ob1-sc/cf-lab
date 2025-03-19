locals {
  stable_config = {
    management_network_transport_zone = data.nsxt_policy_transport_zone.tz.path
    management_network_tier1_lr_id = nsxt_policy_tier1_gateway.t1_router_avi_mgmt.path
    management_network_segment_id = nsxt_policy_segment.avi_mgmt_segment.path
    vip_network_transport_zone = data.nsxt_policy_transport_zone.tz.path
    vip_network_tier1_lr_id = nsxt_policy_tier1_gateway.t1_router_avi_vip.path
    vip_network_tier1_lr_display_name = nsxt_policy_tier1_gateway.t1_router_avi_vip.display_name
    vip_network_segment_id = nsxt_policy_segment.avi_vip_segment.path
    nsxt_policy_group_gorouters_path = nsxt_policy_group.gorouters.path
    nsxt_policy_group_diego_brain_path = nsxt_policy_group.diego_brain.path
  }
}

output "stable_config_yaml" {
  value     = yamlencode(local.stable_config)
  sensitive = false
}