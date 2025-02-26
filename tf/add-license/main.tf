terraform {
  required_providers {
    nsxt = {
      source  = "vmware/nsxt"
      version = "~> 3.0"
    }
    avi = {
      source  = "vmware/avi"
      # version = "22.1.5"
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
  avi_version = "31.1.1"
	avi_tenant     = var.avi_tenant
}

provider "vsphere" {
  user                 = var.avi_controller_vcenter_username
  password             = var.avi_controller_vcenter_password
  vsphere_server       = var.avi_controller_vcenter_host
  allow_unverified_ssl = true
}

resource "avi_systemconfiguration" "controller" {
  uuid                      = "default-uuid"
  welcome_workflow_complete = true
  default_license_tier = "ENTERPRISE"
  ntp_configuration {
    ntp_servers {
      server {
        type = "DNS"
        addr = "time.google.com"
      }
    }
    ntp_servers {
      server {
        type = "DNS"
        addr = "time1.google.com"
      }
    }
    ntp_servers {
      server {
        type = "DNS"
        addr = "time2.google.com"
      }
    }
    ntp_servers {
      server {
        type = "DNS"
        addr = "time3.google.com"
      }
    }
  }
  dns_configuration {
    server_list {
      addr = "8.8.8.8"
      type = "V4"
    }
    server_list {
      addr = "8.8.4.4"
      type = "V4"
    }
  }
  global_tenant_config {
    se_in_provider_context       = true
    tenant_access_to_provider_se = true
    tenant_vrf                   = false
  }
  email_configuration {
    smtp_type = "SMTP_NONE"
  }

  portal_configuration {
    allow_basic_authentication = true
  }

  lifecycle {
    ignore_changes = [ ssh_ciphers, ssh_hmacs, uuid ]
  }
}


resource "null_resource" "add_license" {
  depends_on = [avi_systemconfiguration.controller]

  provisioner "local-exec" {
    command = "curl -X PUT -H \"Authorization: Basic ${base64encode("${var.avi_username}:${var.avi_password}")}\" -H \"Content-Type: application/json\" -d '{\"serial_key\":\"${var.avi_license_key}\"}' -k https://${var.avi_controller}/api/license"
  }
}

# This does not work, getting the error "Backup configuration with this Name and Tenant ref already exists."
# Using the REST API call below instead 
resource "avi_backupconfiguration" "backup_config" {
  name = "Backup-Configuration"
  backup_passphrase = var.avi_password
  tenant_ref = var.avi_tenant
  save_local = true
}

# data "avi_backupconfiguration" "system_backup_configuration" {
#     name = "Backup-Configuration"
# }

# output "curl" {
#   sensitive = true
#   value = "curl -X PUT -H \"Authorization: Basic ${base64encode("${var.avi_username}:${var.avi_password}")}\" -H \"Content-Type: application/json\" -d '{\"name\":\"Backup-Configuration\",\"backup_passphrase\":\"${var.avi_password}\",\"save_local\":\"true\"}' -k https://${var.avi_controller}/api/backupconfiguration/${data.avi_backupconfiguration.system_backup_configuration.uuid}"
# }
# resource "null_resource" "add_backup_passphrase" {
#   depends_on = [avi_systemconfiguration.controller]
#   provisioner "local-exec" {
#     command = "curl -X PUT -H \"Authorization: Basic ${base64encode("${var.avi_username}:${var.avi_password}")}\" -H \"Content-Type: application/json\" -d '{\"name\":\"Backup-Configuration\",\"backup_passphrase\":\"${var.avi_password}\",\"save_local\":\"true\"}' -k https://${var.avi_controller}/api/backupconfiguration/${data.avi_backupconfiguration.system_backup_configuration.uuid}"
#   }
# }
