#!/bin/bash
#####################################################################
#
# Initialize Socius Live environment
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

if [ $(grep "YOUR_PROJECT_NAME" "${MYCONF}" | wc -l ) -eq 1 ]
then
    echo "You did not set your project in etc/project.conf. Please do and restart"
    # exit 0
fi

for file in "${MYCONF}" "${MYLIB}" "${MYDIR}/../lib/gcelib.sh" ; do
	[ -f ${file} ] && source ${file} || { 
		echo "Could not find required file ${file}. Exiting..."
		exit 0
	}
done 

# Check if we are sudoer or not
if [ $(is_sudoer) -eq 0 ]; then
    die "You must be root or sudo to run this script"
fi

# Check install of all dependencies
ensure_cmd_or_install_package_apt jq jq
ensure_cmd_or_install_package_apt awk awk
 # This is to install json (node)
ensure_cmd_or_install_package_apt node nodejs npm
sudo ln -sf /usr/bin/nodejs /usr/local/bin/node
ensure_cmd_or_install_package_npm json json
ensure_cmd_or_install_package_npm yaml2json yaml2json
ensure_cmd_or_install_package_npm json2yaml json2yaml
ensure_cmd_or_install_package_npm json json
# sudo npm install json

# Check install Google Cloud SDK 
ensure_gcloud_or_install
log debug ready to start...

switch_project

# Use this cluster & set creds for k8s
gcloud config set container/cluster -q "${APP_CLUSTER_ID}" \
    && log info Selected ${APP_CLUSTER_ID} as current GKE cluster \
    || die Could not switch current GKE cluster
gcloud container clusters get-credentials  -q "${APP_CLUSTER_ID}" \
    && log info Set kubectl credentials for ${APP_CLUSTER_ID} \
    || die Could not set kubectl credentials for ${APP_CLUSTER_ID}

# Finish
log info Successfully switched to project.conf 
