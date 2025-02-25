# Avi NSX-T Cloud Deployment for Tanzu Application Service with Terraform

This Terraform script

- deploys a NSX Tier-1 Gateway and Segment for the Avi Management Network
- deploys a NSX Tier-1 Gateway and Segment for the Avi VIP Network
- deploys a NSX Group used for Gorouter VMs
- configures a vSphere Content Library to be used by Avi for the Service Engine VMs
- configures Avi NSX Cloud with Networks using static IP addresses for VIPs and SEs (Avi Management Network can also be used with DHCP enabled, for this the Terraform script has to be adopted accordingly)
- imports TAS Gorouter SSL Certificates and Opsman Root CA
- creates a Virtual Server with a static VIP and a Pool consisting of the Gorouter VMs

## Prerequisites

- Avi Controller deployed and configured with an Avi Enterprise License
- NSX Tier-0, Edge Cluster and a Transport Zone preconfigured

## Open Topics

Things to be worked on to extend the Terraform scripts:

- use DHCP enabled Avi Management network (note: DHCP can't be used for the Avi Vip Network)
- use a Terraform [remote Backend](https://developer.hashicorp.com/terraform/language/backend)

## Usage

### Deployment 

Copy the [terraform.tfvars.example](./terraform.tfvars.example) and create your `.tfvars` file with all parameters included and then execute the script:

```shell
terraform apply
```

### Destroy

In order to destroy everything:

1. Navigate to Avi Controller UI to `Infrastructure -> Cloud Resources -> Service Engine`
1. select the cloud from the dropdown and delete all Service Engines assiciated with this cloud
1. run `terraform destroy`

## Known Issues

### Destroy fails for avi_cloud because it is referred by a vCenterServer object

The error is

```
Error: Encountered an error on DELETE request to URL https://172.20.16.2/api/cloud/cloud-cef9f650-03e9-43e5-810f-31798ebd639f: HTTP code: 400; error from Controller: map[error:Cannot delete, object is referred by: [VCenterServer vcenter]]
```

This might happen if the resource `avi_vcenterserver.vcenter` has been deleted already and removed from the tfstate file and if afterwards the `terraform destroy` fails BEFORE destroying the `avi_cloud.nsxt_cloud` resource. This happens especially if Service Engines are still running associated with that cloud, then cloud deletion is blocked by those referred Service Engines.

The Workaround to get around this, after you have deleted the Service Engines from Avi Controller UI/API is to run `terraform apply` again, which brings back the `avi_vcenterserver.vcenter` resource, and immediately after that run `terraform destroy` (when Service Engines have not been created yet).

To prevent this in general, delete all associated Service Engines before running `terraform destroy`.
