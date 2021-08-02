#!/bin/bash

set -eu
set -o errexit

export CLUSTER_NAME=${CLUSTER_NAME:-gloo-tutorial}
CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# create registry container unless it already exists
export CONTAINER_REGISTRY_NAME='kind-registry.local'
export CONTAINER_REGISTRY_PORT='5000'

running="$(docker inspect -f '{{.State.Running}}' "${CONTAINER_REGISTRY_NAME}" 2>/dev/null || true)"
if [ "${running}" != 'true' ]; then
  docker run \
    -d --restart=always -p "${CONTAINER_REGISTRY_PORT}:5000" --name "${CONTAINER_REGISTRY_NAME}" \
    registry:2
fi

# create a cluster with the local registry enabled in containerd
kind create cluster --name="${CLUSTER_NAME}" --config="${CURRENT_DIR}/kind-cluster-config.yml"

# connect the registry to the cluster network only for new 
if [ "${running}" != 'true' ]; then
  docker network connect "kind" "${CONTAINER_REGISTRY_NAME}"
fi

## Label nodes for using registry 
# tell https://tilt.dev to use the registry
# https://docs.tilt.dev/choosing_clusters.html#discovering-the-registry
for node in $(kind get nodes --name="$CLUSTER_NAME"); do
  kubectl annotate node "${node}" \
    "tilt.dev/registry=localhost:${CONTAINER_REGISTRY_PORT}" \
    "tilt.dev/registry-from-cluster=${CONTAINER_REGISTRY_NAME}:${CONTAINER_REGISTRY_PORT}";
done

## Label worker nodes
kubectl  get nodes --no-headers -l '!node-role.kubernetes.io/master' -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}' | xargs -I{} kubectl label node {} node-role.kubernetes.io/worker=''

## Setup helm

helm repo add stable https://charts.helm.sh/stable
helm repo update
