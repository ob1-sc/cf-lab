###############################
# Avi Management Network     #
###############################

variable "avi_mgmt_segment_name" {
  description = "Segment Name for Avi Management Network"
  type        = string
}

variable "avi_mgmt_network_dhcp_enabled" {
  type        = bool
  default     = false
  description = "whether to use DHCP for the Avi Management network or using static IP ranges"
}

variable "avi_mgmt_dhcp_server_address" {
  description = "The IPv4 address of the DHCP server if enabled"
  type        = string
  default     = ""
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

#################################
# TPCF Infra Network Configuration #
#################################

variable "tpcf_infra_segment_name" {
  description = "Segment Name for TPCF Infra Network"
  type        = string
}

variable "tpcf_infra_segment_ip_addr" {
  description = "TPCF Infra Segment IP Address"
  type        = string
}

variable "tpcf_infra_segment_ip_addr_mask" {
  description = "Subnet Mask for TPCF Infra Segment"
  type        = number
}

variable "tpcf_infra_segment_gateway" {
  description = "Gateway for TPCF Infra Segment"
  type        = string
}

#################################
# TPCF Deployment Network Configuration #
#################################

variable "tpcf_deployment_segment_name" {
  description = "Segment Name for TPCF Deployment Network"
  type        = string
}

variable "tpcf_deployment_segment_ip_addr" {
  description = "TPCF Deployment Segment IP Address"
  type        = string
}

variable "tpcf_deployment_segment_ip_addr_mask" {
  description = "Subnet Mask for TPCF Deployment Segment"
  type        = number
}

variable "tpcf_deployment_segment_gateway" {
  description = "Gateway for TPCF Deployment Segment"
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
  type = string
}

variable "nsxt_password" {
  type      = string
  sensitive = true
}

variable "t1_avi_mgmt_name" {
  description = "T1 Router Name for Avi Management"
  type        = string
}

variable "t1_avi_vip_name" {
  description = "T1 Router Name for Avi VIP"
  type        = string
}

variable "t1_tpcf_name" {
  description = "T1 Router Name for TPCF"
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