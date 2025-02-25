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

## Backlog

Things to be worked on to extend the Terraform scripts:

- use DHCP enabled Avi Management network (note: DHCP can't be used for the Avi Vip Network)
