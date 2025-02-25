##############################
# Avi general variables      #
##############################

variable "avi_controller" {
  description = "Avi Controller IP or Hostname"
  type        = string
}

variable "avi_username" {
  type        = string
}

variable "avi_password" {
  type        = string
  sensitive   = true
}

variable "avi_tenant" {
  type        = string
  default     = "admin"
}

variable "avi_cloud_name" {
  description = "Name of the Avi Cloud"
  type        = string
}

variable "avi_health_monitor_name" {
  type        = string
}

###############################
# Avi Management Network     #
###############################

variable "avi_mgmt_segment_name" {
  description = "Segment Name for Avi Management Network"
  type        = string
}

variable "avi_mgmt_network_dhcp_enabled" {
  type = bool
  default = false
  description = "whether to use DHCP for the Avi Management network or using static IP ranges"
}

variable "avi_mgmt_dhcp_server_address" {
  description = "The IPv4 address of the DHCP server if enabled"
  type = string
  default = ""
}
variable "avi_mgmt_network_ip_addr" {
  description = "Avi Management Network IP Address"
  type        = string
}

variable "avi_mgmt_network_ip_addr_mask" {
  description = "Subnet Mask for Avi Management Network"
  type        = number
}

variable "avi_mgmt_segment_gateway" {
  description = "Gateway for Avi Management Network"
  type        = string
}

variable "avi_mgmt_segment_static_ip_begin" {
  description = "Start of Static IP Range for Avi Management"
  type        = string
}

variable "avi_mgmt_segment_static_ip_end" {
  description = "End of Static IP Range for Avi Management"
  type        = string
}


#################################
# Avi VIP Network Configuration #
#################################

variable "avi_vip_segment_name" {
  description = "Segment Name for VIP Network"
  type        = string
}

variable "avi_vip_segment_ip_addr" {
  description = "VIP Segment IP Address"
  type        = string
}

variable "avi_vip_segment_ip_addr_mask" {
  description = "Subnet Mask for VIP Segment"
  type        = number
}

variable "avi_vip_segment_gateway" {
  description = "Gateway for VIP Segment"
  type        = string
}

variable "avi_vip_segment_static_ip_begin" {
  description = "Start of Static IP Range for VIP Segment"
  type        = string
}

variable "avi_vip_segment_static_ip_end" {
  description = "End of Static IP Range for VIP Segment"
  type        = string
}

###############################
# NSX-T Configuration        #
###############################

variable "nsxt_host" {
  description = "NSX-T Manager Hostname or IP"
  type        = string
}

variable "nsxt_username" {
  type        = string
}

variable "nsxt_password" {
  type        = string
  sensitive   = true
}

variable "t1_avi_mgmt_name" {
  description = "T1 Router Name for Avi Management"
  type        = string
}

variable "t1_avi_vip_name" {
  description = "T1 Router Name for Avi VIP"
  type        = string
}

variable "t0_router_name" {
  description = "T0 Router Name"
  type        = string
}

variable "edge_cluster_name" {
  description = "Edge Cluster Name"
  type        = string
}

variable "transport_zone_name" {
  description = "Transport Zone Name"
  type        = string
}

###########################
# vSphere Variables #
###########################

variable "vcenter_datacenter" {
  description = "vCenter Datacenter for Avi Integration"
  type        = string
}

variable "vcenter_cluster" {
  description = "vCenter Cluster for Avi Integration"
  type        = string
}

variable "vcenter_datastore" {
  description = "vCenter Datastore for Avi Integration"
  type        = string
}

variable "vcenter_host" {
  description = "vCenter Host for Avi Integration"
  type        = string
}

variable "vcenter_username" {
  description = "vCenter Username for Avi Integration"
  type        = string
}

variable "vcenter_password" {
  description = "vCenter Password for Avi Integration"
  type        = string
  sensitive   = true
}

variable "vcenter_content_library_avi" {
  description = "name of Content Library to be created for Avi"
  type        = string
}

###########################
# Miscellaneous Variables #
###########################

variable "opsman_ca_cert" {
  description = "Ops Manager CA Certificate"
  type        = string
}

variable "tas_gorouter_vip" {
  description = "TAS GoRouter VIP Address"
  type        = string
}
