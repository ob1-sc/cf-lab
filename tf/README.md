# Avi NSX-T Cloud Deployment for Tanzu Application Service with Terraform

This Terraform script

- deploys a NSX Tier-1 Gateway and Segment for the Avi Management Network
- deploys a NSX Tier-1 Gateway and Segment for the Avi VIP Network
- deploys a NSX Group used for Gorouter VMs and a group for the Control VM for `cf ssh` (this guide uses TAS Small Footprint where the Diego brain runs on the Control VM, if using full TAS, change the [membership criteria](./nsx-avi.tf#L100-L107) accordingly)
- configures a vSphere Content Library to be used by Avi for the Service Engine VMs
- deploys Avi Controller on vSphere and adds a License
- configures Avi NSX Cloud with Networks
- imports TAS Gorouter SSL Certificates and Opsman Root CA to Avi
- creates a Virtual Server with a static VIP and a Pool consisting for the Gorouters and for `cf ssh`

## Prerequisites

- an empty Content Library to store the Avi Controller OVA
- NSX Tier-0, Edge Cluster and a Transport Zone preconfigured

## Usage

### Deployment

#### Deploy Avi Controller on vSphere

1. navigate to [controller-deployment](./controller-deployment/)
1. Import Avi Controller OVA to a Content Library:

    ```shell
    # upload Avi Controller OVA from local filesystem to vCenter
    govc datastore.upload /path/to/your.ova your-folder/your.ova
    # import the OVA to a Content Library
    govc library.import -n "your-template-name" your-content-library "your-folder/your.ova"
    ```

1. Copy the [terraform.tfvars.example](./controller-deployment/terraform.tfvars.example) and create your `.tfvars` file with your parameters
1. Run Terraform:

    ```shell
    terraform apply
    ```

#### Create Avi Load Balancer for TAS

1. Copy the [terraform.tfvars.example](./terraform.tfvars.example) and create your `.tfvars` file with your parameters
1. Create a certificate file `tas.crt` and related private key file `tas.key` with the TLS certs you use for the Gorouters and store them in this directory
1. Run Terraform:

    ```shell
    terraform apply
    ```

### Destroy

In order to destroy everything:

1. run `terraform destroy`
1. Follow the output! It will ask you to delete Service Engines associated with the Cloud. In order to do that, log in to Avi Controller UI, navigate to `Infrastructure -> Cloud Resources -> Service Engine`, then select the cloud from the dropdown and delete all Service Engines. After a few seconds, terraform will continue to destroy resources.

## Known Issues

Things that need to be improved:

1. Requires version 22.1.5 of the Terraform Avi Provider which is still able to update existing non-Terraform-managed objects. With version >=22.1.6 you will get errors like this:

    ```shell
    │ Error: Encountered an error on POST request to URL https://172.20.16.3/api/vrfcontext: HTTP code: 409; error from Controller: map[error:Vrf context with this Name, Tenant ref and Cloud ref already exists.]
    │ 
    │   with avi_vrfcontext.avi_vip_vrf,
    │   on avi.tf line 227, in resource "avi_vrfcontext" "avi_vip_vrf":
    │  227: resource "avi_vrfcontext" "avi_vip_vrf" {
    ```

    Note: You can still use version 22.1.5 to automate Avi Controller 31.1.1.

1. when running `terraform apply` the first time sometimes results in the error:

    ```shell
    avi_virtualservice.rabbit_17001: Creation complete after 1s [id=https://172.20.16.3/api/virtualservice/virtualservice-c3abe7e1-ae58-481e-bd32-9eaaaff1302c]
    ╷
    │ Error: Encountered an error on POST request to URL https://172.20.16.3/api/virtualservice: HTTP code: 500; error from Controller: map[error:record not found]
    │
    │   with avi_virtualservice.tas,
    │   on avi-gorouter.tf line 79, in resource "avi_virtualservice" "tas":
    │   79: resource "avi_virtualservice" "tas" {
    │
    ╵
    ```

    I don't know why this happens, but you can solve it by simply re-running `terraform apply`.