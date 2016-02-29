# Running k8s locally
## Purpose

This project explains how to run a dev k8s cluster, whether locally or on GKE. 

## Introduction

When developing with Docker and containers, Kubernetes represents an elegant way of running clusters. It's also the technology behind GKE. While it's pretty trivial to run and play with, some wrappers to make it easy to alternate between clusters, dev, staging, prod and so on might be useful. It is the purpose of this project. 

## Usage
### Cloning the repository

First you need to make sure you cloned this repo: 

	sudo apt-get update && sudo apt-get install git-core
	[ ! -d ~/src ] && mkdir -p ~/src
	cd ~/src
	git clone https://github.com/SaMnCo/easy-gke
	cd easy-gke

### Configuring project
#### GKE

First you need to create a project in your Google Cloud Platform, then configure the following settings in **etc/project.conf**: 

	# Project Settings
	PROJECT_ID=<PUT YOUR GCP PROJECT ID HERE>
	REGION=us-central1
	ZONE=${REGION}-f
	DEFAULT_MACHINE_TYPE="n1-standard-2"

	# Cluster Settings
	APP_CLUSTER_ID=<PUT YOUR K8S CLUSTER NAME HERE>
	APP_CLUSTER_SIZE=3

As you can imagine, the first part refers to where you want to deploy your GKE cluster. 

The second part is about specific informations about your GKE cluster itself. For the APP_CLUSTER_ID, we recommend using only alphanumerical values (and NO special characters) 

#### Local Deployment

If you want to run your mini GKE locally, setup the project ID as "local". The rest of the settings do not matter so your project configuration could look like: 

	# Project Settings
	PROJECT_ID=local

### Bootstrapping

You just need to run the bootstrap script

	./bin/bootstrap.sh --project=./etc/project.conf

Note you can obviously have several project.conf files stored in the etc folder, and alternate. 

**Note**: You need to be sudoer for this. Anyway the code will tell you if you can't run it. 

This will 

* Install all requirements for the whole project if needed
* Install the gcloud command line, and update it to the latest version if needed
* Create a new cluster on GKE using the provided settings
* Download the cluster credentials for the kubectl CLI

### Switch between projects

At some points in time, you may have several projects (dev/staging/prod for example) and you would like to switch between them. Just do

	./bin/switch.sh --project=./etc/project.conf

to switch your configuration from the previous environment to the new project.conf system. 

### Wrapping up

Once you're done with a project, just run

	./bin/cleanup.sh --project=./etc/project.conf

This will delete everything related to the project. 

# Final notes

This work was seeded and sponsored by Blended Technologies (www.blended.io) as part of an effort to dockerize a more complex application. We decided to open source the project to show our gratitude to the great folks at Couchbase (special kudos to Traun Leyden) who did a great lot at explaining how to run Couchbase in docker containers. 

