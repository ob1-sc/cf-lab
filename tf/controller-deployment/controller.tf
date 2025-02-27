

data "vsphere_datacenter" "dc" {
  name = var.avi_controller_vcenter_datacenter
}

data "vsphere_datastore" "datastore" {
  name          = var.avi_controller_vcenter_datastore
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_compute_cluster" "cluster" {
  name          = var.avi_controller_vcenter_cluster
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_resource_pool" "pool" {
  name          = "${var.avi_controller_vcenter_cluster}/Resources"
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "avi_controller_network" {
  name          = var.avi_controller_vsphere_network_name
  datacenter_id = data.vsphere_datacenter.dc.id
}

resource "vsphere_folder" "avi_controller_folder" {
  count         = var.avi_controller_vsphere_folder == null ? 0 : 1
  path          = var.avi_controller_vsphere_folder
  type          = "vm"
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_content_library" "avi_controller" {
  name = var.avi_controller_content_library_name
}

data "vsphere_content_library_item" "avi_controller" {
  name       = var.avi_controller_content_library_item_name
  type       = "vm-template"
  library_id = data.vsphere_content_library.avi_controller.id
}

resource "vsphere_virtual_machine" "avi_controller" {
  name             = var.avi_controller_vm_name
  datastore_id     = data.vsphere_datastore.datastore.id
  resource_pool_id = data.vsphere_resource_pool.pool.id
  folder           = var.avi_controller_vsphere_folder == null ? null : vsphere_folder.avi_controller_folder[0].id
  network_interface {
    network_id = data.vsphere_network.avi_controller_network.id
  }

  num_cpus                   = var.avi_controller_cpu
  memory                     = var.avi_controller_memory_in_mb
  wait_for_guest_net_timeout = 4
  guest_id                   = "ubuntu64Guest"

  disk {
    size             = var.avi_controller_disk_size_in_gb
    label            = "Hard Disk 1"
    thin_provisioned = false
  }

  clone {
    template_uuid = data.vsphere_content_library_item.avi_controller.id
  }

  vapp {
    properties = {
      "mgmt-ip"    = var.avi_controller
      "mgmt-mask"  = var.avi_controller_vsphere_network_mask
      "default-gw" = var.avi_controller_vsphere_network_gateway_ip
    }
  }
}

resource "null_resource" "wait_avi_controller" {
  depends_on = [vsphere_virtual_machine.avi_controller]

  provisioner "local-exec" {
    command = "until $(curl --output /dev/null --silent --head -k https://${var.avi_controller}); do echo 'Waiting for Avi Controllers to be ready'; sleep 10 ; done"
  }
}

# wait 10s as otherwise the controller is not yet ready to create a user
resource "time_sleep" "wait_10_seconds" {
  depends_on = [null_resource.wait_avi_controller]
  create_duration = "10s"
}


# change default password of Avi admin user
resource "avi_useraccount" "avi_user" {
  depends_on = [time_sleep.wait_10_seconds]
  username     = var.avi_tenant
  old_password = var.avi_default_password
  password     = var.avi_password
}
