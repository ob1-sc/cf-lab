provider "vsphere" {
  user                 = var.vcenter_username
  password             = var.vcenter_password
  vsphere_server       = var.vcenter_host
  allow_unverified_ssl = true
}

data "vsphere_datacenter" "dc" { 
	name = var.vcenter_datacenter 
}

data "vsphere_compute_cluster" "cluster" {
  name          = var.vcenter_cluster
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_datastore" "datastore" {
  name          = var.vcenter_datastore
  datacenter_id = data.vsphere_datacenter.dc.id
}

resource "vsphere_content_library" "library" {
  name            = "avi-content-library"
  storage_backing = [data.vsphere_datastore.datastore.id]
}

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