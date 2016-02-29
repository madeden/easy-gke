#!/bin/bash
#####################################################################
#
# Initialize Socius Live script
#
# Notes: 
#   * GCloud Disk Doc: https://cloud.google.com/compute/docs/disks/#comparison_of_disk_types
# 
# Maintainer: Samuel Cozannet <samuel@blended.io>, http://blended.io 
#
#####################################################################

# Validating I am running on debian-like OS
[ -f /etc/debian_version ] || {
	echo "We are not running on a Debian-like system. Exiting..."
	exit 0
}

# Load Configuration
MYNAME="$(readlink -f "$0")"
MYDIR="$(dirname "${MYNAME}")"
MYCONF="${MYDIR}/../etc/project.conf"
MYLIB="${MYDIR}/../lib/bashlib.sh"

for file in "${MYCONF}" "${MYLIB}" "${MYDIR}/../lib/gcelib.sh"; do
	[ -f ${file} ] && source ${file} || { 
		echo "Could not find required files. Exiting..."
		exit 0
	}
done 

# Check install of all dependencies
ensure_cmd_or_install_package_apt jq jq

# Check install Google Cloud SDK 
ensure_gcloud_or_install
log debug ready to start...

# Initialize environment
switch_project

#####################################################################
#
# Delete k8s cluster & assets
#
#####################################################################

gcloud container clusters delete -q "${APP_CLUSTER_ID}" \
    2>/dev/null \
    && log info Successfully destroyed the cluster named ${APP_CLUSTER_ID} \
    || die Could not destroy GKE cluster 

# Cleanup Temporary files
[ -d "${MYDIR}/../tmp" ] && rm -rf "${MYDIR}/../tmp"

