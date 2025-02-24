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
  name            = var.vcenter_content_library_avi
  storage_backing = [data.vsphere_datastore.datastore.id]
}
