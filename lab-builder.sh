#!/usr/bin/env bash
[[ -z $DEBUGX ]] || set -x

## Always call finish when scripts exits (error or success)
function finish {
  echo "END"
}
trap finish EXIT

#################################################
### DEFINE VARIABLES (WITH OPTIONAL DEFAULTS) ###
#################################################
MODE=

#############################################
### Read parameters from the command line ###
#############################################
while getopts 'm:h' arg; do
  case $arg in
  m) export MODE="$OPTARG" ;;
  \? | h) usage ;;
  esac
done

########################
### DEFINE FUNCTIONS ###
########################

## Print script usage information
function usage() {
  echo "Usage:"
  echo "Environment variables to be set:"
  echo "VCENTER_USERNAME     - The username for target VMware vCenter Server"
  echo "VCENTER_PASSWORD     - The password for target VMware vCenter Server"
  echo "NSXT_LICENSE_KEY     - The NSXT licence key"
  echo "AVI_DEFAULT_PASSWORD - The AVI default password"
  echo "SOFTWARE_DIR         - Location of software binaries"
  echo "CONFIG_DIR           - Location of configuration files for target deployment environment"
  echo "LAB_BUILDER_DIR      - Location of vmware-lab-builder project"
  echo ""
  echo "Command line arguments:"
  echo "-m - The mode to run the lab builder, valid options are 'deploy' or 'destroy'"
  echo "-h - Script help/usage"
}

## Validate script variables have all been correctly set
function validate() {

  [ -z "$VCENTER_USERNAME" ] && return 1
  [ -z "$VCENTER_PASSWORD" ] && return 1
  [ -z "$NSXT_LICENSE_KEY" ] && return 1
  [ -z "$AVI_DEFAULT_PASSWORD" ] && return 1
  [ -z "$SOFTWARE_DIR" ] && return 1
  [ -z "$CONFIG_DIR" ] && return 1
  [ -z "$LAB_BUILDER_DIR" ] && return 1

  [ -d "$SOFTWARE_DIR" ] || { echo "Error: $SOFTWARE_DIR is not a valid path"; return 1; }
  [ -d "$CONFIG_DIR" ] || { echo "Error: $CONFIG_DIR is not a valid path"; return 1; }
  [ -d "$LAB_BUILDER_DIR" ] || { echo "Error: $LAB_BUILDER_DIR is not a valid path"; return 1; }    

  if [[ ! $MODE =~ ^(deploy|destroy)$ ]]; then 
    echo "Error: -m flag must be deploy or destroy"
    return 1
  fi

  return 0
}

## Main script logic
function main() {

    docker run --rm \
    --env PARENT_VCENTER_USERNAME=${VCENTER_USERNAME} \
    --env PARENT_VCENTER_PASSWORD=${VCENTER_PASSWORD} \
    --env SOFTWARE_DIR='/software_dir' \
    --env ANSIBLE_FORCE_COLOR='true' \
    --env NSXT_LICENSE_KEY=${NSXT_LICENSE_KEY:-na} \
    --env AVI_DEFAULT_PASSWORD=${AVI_DEFAULT_PASSWORD:-na} \
    --volume ${SOFTWARE_DIR}:/software_dir \
    --volume ${CONFIG_DIR}/lab-builder:/config_dir \
    --volume ${LAB_BUILDER_DIR}:/work \
    laidbackware/vmware-lab-builder:v12 \
    ansible-playbook \
    /work/$MODE.yml --extra-vars '@/config_dir/1host-nsx-avi-tas.yml'

}

# validate and run the script
if validate; then
  main
else
  usage
fi