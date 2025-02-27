data "vsphere_datacenter" "dc" { 
  provider = vsphere.dataplane
	name = var.data_plane_vcenter_datacenter 
}

data "vsphere_compute_cluster" "cluster" {
  provider = vsphere.dataplane
  name          = var.data_plane_vcenter_cluster
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_datastore" "datastore" {
  provider = vsphere.dataplane
  name          = var.data_plane_vcenter_datastore
  datacenter_id = data.vsphere_datacenter.dc.id
}

resource "vsphere_content_library" "library" {
  provider = vsphere.dataplane
  name            = var.data_plane_vcenter_content_library_avi
  storage_backing = [data.vsphere_datastore.datastore.id]
}
