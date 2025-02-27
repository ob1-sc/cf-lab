##############################
# Avi general variables      #
##############################

variable "avi_controller_vsphere_network_name" {
  type        = string
}

variable "avi_controller_vsphere_network_mask" {
  type        = string
}

variable "avi_controller_vsphere_network_gateway_ip" {
  type        = string
}

variable "avi_controller_vsphere_folder" {
  type        = string
  default = null
}

variable "avi_controller_content_library_name" {
  type        = string
  default = "avi-controller"
}

variable "avi_controller_content_library_item_name" {
  type        = string
  default = "avi-controller"
}

variable "avi_controller_vm_name" {
  type        = string
  default = "avi-controller"
}


variable "avi_controller_cpu" {
  description = "should be at least 8"
  type        = number
}

variable "avi_controller_memory_in_mb" {
  description = "should be at least 32768"
  type = number
}

variable "avi_controller_disk_size_in_gb" {
  description = "must be at least 128 otherwise OVA deployment fails as virtual disk cannot be shrunk"
  type = number
  default = 128
}

variable "avi_controller" {
  description = "Avi Controller IP or Hostname"
  type        = string
}

variable "avi_username" {
  type = string
}

variable "avi_default_password" {
  type      = string
  sensitive = true
}

variable "avi_password" {
  type      = string
  sensitive = true
}

variable "avi_tenant" {
  type    = string
  default = "admin"
}

###########################
# vSphere Variables #
###########################

variable "avi_controller_vcenter_datacenter" {
  description = "vCenter Datacenter for Avi Integration"
  type        = string
}

variable "avi_controller_vcenter_cluster" {
  description = "vCenter Cluster for Avi Integration"
  type        = string
}

variable "avi_controller_vcenter_datastore" {
  description = "vCenter Datastore for Avi Integration"
  type        = string
}

variable "avi_controller_vcenter_host" {
  description = "vCenter Host for Avi Integration"
  type        = string
}

variable "avi_controller_vcenter_username" {
  description = "vCenter Username for Avi Integration"
  type        = string
}

variable "avi_controller_vcenter_password" {
  description = "vCenter Password for Avi Integration"
  type        = string
  sensitive   = true
}
