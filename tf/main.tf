terraform {
  required_providers {
    nsxt = {
      source  = "vmware/nsxt"
      version = "~> 3.0"
    }
    avi = {
      source  = "vmware/avi"
      version = "22.1.5"
    }
    vsphere = {
      source = "hashicorp/vsphere"
    }
  }
}

provider "nsxt" {
  host                 = var.nsxt_host
  username             = var.nsxt_username
  password             = var.nsxt_password
  allow_unverified_ssl = true
}

provider "avi" {
  avi_controller = var.avi_controller
  avi_username   = var.avi_username
  avi_password   = var.avi_password
  avi_version = "22.1.5"
	avi_tenant     = var.avi_tenant
}

provider "vsphere" {
  user                 = var.avi_controller_vcenter_username
  password             = var.avi_controller_vcenter_password
  vsphere_server       = var.avi_controller_vcenter_host
  allow_unverified_ssl = true
  alias = "avi_controller"
}

provider "vsphere" {
  user                 = var.data_plane_vcenter_username
  password             = var.data_plane_vcenter_password
  vsphere_server       = var.data_plane_vcenter_host
  allow_unverified_ssl = true
  alias = "dataplane"
}
