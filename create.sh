#!/usr/bin/env bash

# Copyright 2018 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# "---------------------------------------------------------"
# "-                                                       -"
# "-  Creates a GKE Cluster                                -"
# "-                                                       -"
# "---------------------------------------------------------"

set -o errexit
set -o nounset
set -o pipefail

ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CLUSTER_NAME=""
ZONE=""
GKE_VERSION=$(gcloud container get-server-config \
  --format="value(defaultClusterVersion)")

# shellcheck source=./common.sh
source "$ROOT/common.sh"

# Ensure the required APIs are enabled
enable_project_api "${PROJECT}" "compute.googleapis.com"
enable_project_api "${PROJECT}" "container.googleapis.com"
enable_project_api "${PROJECT}" "containerregistry.googleapis.com"
enable_project_api "${PROJECT}" "containeranalysis.googleapis.com"
enable_project_api "${PROJECT}" "binaryauthorization.googleapis.com"

# Create a 2-node zonal GKE cluster
# Requires the Beta API to enable binary authorization support
echo "Creating cluster"
gcloud container clusters create "$CLUSTER_NAME" \
  --zone "$ZONE" \
  --cluster-version "$GKE_VERSION" \
  --num-nodes=2 \
  --enable-ip-alias \
  --enable-binauthz \
  --network "projects/argolis-jasper-3/global/networks/workload-vpc" \
  --subnetwork "projects/argolis-jasper-3/regions/australia-southeast1/subnetworks/subnet-sydney" \
  --cluster-ipv4-cidr "100.64.16.0/20" \
  --services-ipv4-cidr "198.18.1.0/24" \
  --enable-private-endpoint \
  --enable-private-nodes \
  --enable-master-authorized-networks \
  --master-ipv4-cidr="172.16.0.16/28" \
  --service-account="gke-node-service-account@argolis-jasper-3.iam.gserviceaccount.com" \
  --security-group "gke-security-groups@wangjasper.altostrat.com"


# Get the kubectl credentials for the GKE cluster.
gcloud container clusters get-credentials "$CLUSTER_NAME" --zone "$ZONE"
