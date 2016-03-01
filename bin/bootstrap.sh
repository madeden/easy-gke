#!/bin/bash
#####################################################################
#
# Bootstraping a Kubernetes Cluster in various environments
# 
# Maintainer: Samuel Cozannet <samuel@blended.io>, http://blended.io 
#
#####################################################################

# Usage: 
# ./bin/bootstrap.sh -p ./etc/project.conf 
# myscript -vfd ./foo/bar/someFile -o /fizz/someOtherFile
# myscript -v -f -d -o/fizz/someOtherFile -- ./foo/bar/someFile 
# myscript --verbose --force --debug ./foo/bar/someFile -o/fizz/someOtherFile
# myscript --output=/fizz/someOtherFile ./foo/bar/someFile -vfd
# myscript ./foo/bar/someFile -df -v --output /fizz/someOtherFile

# Validating I am running on debian-like OS
[ -f /etc/debian_version ] || {
    echo "We are not running on a Debian-like system. Exiting..."
    exit 0
}

# Load Configuration
MYNAME="$(readlink -f "$0")"
MYDIR="$(dirname "${MYNAME}")"
LIBS="$( find "${MYDIR}/../lib" -name '*.sh')"

for file in ${LIBS} ; do
    [ -f ${file} ] && { 
        source ${file} 
    } || { 
        echo "Could not find required file ${file}. Exiting..."
        exit 0
    }
done 

# Check if we are sudoer or not
[ $(is_sudoer) -eq 0 ] && die "You must be root or sudo to run this script"

# Now processing options 
getopt --test > /dev/null
[[ $? != 4 ]] && die "I’m sorry, `getopt --test` failed in this environment."

SHORT=p:v::
LONG=project:verbose::

PARSED=`getopt --options $SHORT --longoptions $LONG --name "$0" -- "$@"`
if [[ $? != 0 ]]; then
    exit 2
fi
eval set -- "$PARSED"

while true; do
    case "$1" in
        -p|--project)
            p="$2"
            shift
            shift
            ;;        
        -v|--verbosity)
            MIN_LOG_LEVEL="$2"
            shift
            ;;
        --)
            shift
            break
            ;;
        *)
            break
            ;;
    esac
done

if [[ $# != 0 ]]; then
    echo "$0: usage: bootstrap.sh -p /path/to/project.conf [-v debug_level]"
    exit 4
fi

# Set verbosity
case "${MIN_LOG_LEVEL}" in 
    "emerg" | "alert" | "crit" | "err" | "warn" | "notice" | "info" | "debug" ) 
        ;; 
    * )
        MIN_LOG_LEVEL="debug"
    ;;
esac

# Testing validity of configuration file
[ "${p}x" = "x" ] && die "Usage: bootstrap.sh -p /path/to/project.conf [ -v debug_level ]"
[ ! -f "${p}" ] && die "Configuration file does not exist."
[ $(grep "YOUR_PROJECT_NAME" "${p}" | wc -l) -eq 1 ] && \
    die "You did not set your project in etc/project.conf. Please do and restart"

# Loading configuration
log debug "Using project configuration file ${p}"
source ${p}

log debug Creating temporary files
[ ! -d "${MYDIR}/../tmp/${PROJECT_ID}" ] && mkdir -p "${MYDIR}/../tmp/${PROJECT_ID}"


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


function create_gke_cluster() {
    # Check install Google Cloud SDK 
    ensure_gcloud_or_install
    log debug ready to start...

    switch_project

    # Create a small k8s cluster on GKE
    gcloud container clusters create -q "${APP_CLUSTER_ID}" \
        --num-nodes "${APP_CLUSTER_SIZE}" \
        --quiet \
        --machine-type "${DEFAULT_MACHINE_TYPE}" \
        2>/dev/null \
        && log info GKE Cluster Created \
        || die Could not create GKE Cluster

    sleep 5

    # Use this cluster & set creds for k8s
    switch_gke_cluster "${APP_CLUSTER_ID}"
    # Adding Secrets
    # If you want, you can store secrets in the secrets/ folder and upload them here
    # kubectl create -f "${MYDIR}/../secrets/quayio.secret.json"
} 

function create_docker_cluster() {
    # Check install Google Cloud SDK 
    ensure_docker_or_install
    log debug ready to start...

    # Create a small k8s cluster locally
    bootstrap_k8s

    # Install kubectl if not there
    ensure_cmd_or_install_kubectl

    # Use this cluster & set creds for k8s
    # switch_docker_cluster

    # Adding Secrets
    # If you want, you can store secrets in the secrets/ folder and upload them here
    # kubectl create -f "${MYDIR}/../secrets/quayio.secret.json"
} 

# Finish
log info Bootstrap finished. You can now install the application

create_docker_cluster