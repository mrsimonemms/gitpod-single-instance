#!/bin/bash

# Team Quickpod
#
#     curl https://raw.githubusercontent.com/MrSimonEmms/gitpod-single-instance/develop/run.sh | bash
#
# This was done on the Gitpod 2022 off-site hackathon in Ericeira, Portugal by
# Lucas Valtl, Simon Emms and Jurgen Leschner.
#
# With special thanks to our awesome community member and Gitpod Hero, Jimmy B
#
# QUICKPOD FOR THE WIN!!!

set -euo pipefail

DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)

INSTALLER_VERSION=release-2022.02.0.1

color() {
  echo "\e[$1m$2\e[0m"
}

success() {
  local logoColor=33
  local codeColor=34
  local textColor="1;37"

  local msg="\n"
  msg="$msg$(color $logoColor "    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@")\n"
  msg="$msg$(color $logoColor "    @@@@@@@@@@@@@@@(,&@@@@@@@@@@@@@@")\n"
  msg="$msg$(color $logoColor "    @@@@@@@@@@@,,,,,,,,,@@@@@@@@@@@@")$(color $textColor "    Welcome to Gitpod")\n"
  msg="$msg$(color $logoColor "    @@@@@@(,,,,,,,,,,,,@@@@@@@@@@@@@")\n"
  msg="$msg$(color $logoColor "    @@@*****,,,,,,,@@@@@@@@@@@/#@@@@")$(color $textColor "    In a few minutes, your installation will be complete. In the meantime,")\n"
  msg="$msg$(color $logoColor "    @@********/@@@@@@@@@@,,,,,,,,,,@")$(color $textColor "    have a look through our documentation https://www.gitpod.io/docs")\n"
  msg="$msg$(color $logoColor "    @%******@@@@@@@@%,,,,,,,,,,,,,,@")\n"
  msg="$msg$(color $logoColor "    @%******@@@@@/******,,,,,,,,,,,@")$(color $textColor "    Your installation will be at: https://localhost}")\n"
  msg="$msg$(color $logoColor "    @%******@@@@@********@@@@,,,,,,@")\n"
  msg="$msg$(color $logoColor "    @%******@@@@@@@@@@@@@@@@@***,,,@")$(color $textColor "    Run ")$( color $codeColor "kubectl get pods")\n"
  msg="$msg$(color $logoColor "    @@********#@@@@@@@@@@@/********@")$(color $textColor "    to check the status of your installation.")\n"
  msg="$msg$(color $logoColor "    @@@@@@/*******************(@@@@@")\n"
  msg="$msg$(color $logoColor "    @@@@@@@@@@&***********@@@@@@@@@@")\n"
  msg="$msg$(color $logoColor "    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@")\n"

  echo -e "$msg"
}

#function installer() {
#  docker run --rm \
#    -v="${HOME}/.kube:${HOME}/.kube" \
#    -v="${PWD}:${PWD}" \
#    -w="${PWD}" \
#    "eu.gcr.io/gitpod-core-dev/build/installer:${INSTALLER_VERSION}" \
#    "${@}"
#}

if ! command -v docker &> /dev/null; then
  echo "docker could not be found - please visit https://docs.docker.com/get-docker/ for installation instructions"
  exit 1
fi

if ! command -v k3d &> /dev/null; then
  echo "Installing k3d"
  wget -q -O - https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
fi

if ! command -v kubectl &> /dev/null; then
  echo "Installing Kubectl"
  curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
  sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
fi

if ! command -v helm &> /dev/null; then
  echo "Installing Helm"
  curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi

echo "Provisioning k3d cluster"

k3d cluster delete gitpod

echo "Building image"

touch /tmp/etc-hosts

echo "Provision K3d"
k3d cluster create --config https://raw.githubusercontent.com/MrSimonEmms/gitpod-single-instance/develop/k3d.yaml

export KUBECONFIG="$(k3d kubeconfig write gitpod || true)"

echo "Installing cert-manager..."
helm upgrade \
    --atomic \
    --cleanup-on-fail \
    --create-namespace \
    --install \
    --namespace cert-manager \
    --repo https://charts.jetstack.io \
    --reset-values \
    --set installCRDs=true \
    --wait \
    cert-manager \
    cert-manager

echo "Create certificates..."
kubectl apply -f https://raw.githubusercontent.com/MrSimonEmms/gitpod-single-instance/develop/certificate.yaml

CONFIG_FILE="${DIR}/gitpod-config.yaml"

# @todo(sje) generate from installer
#installer init > "${CONFIG_FILE}"
#
#yq e -i '.domain = "localhost"' "${CONFIG_FILE}"
#yq e -i '.workspace.runtime.containerdRuntimeDir = "/run/k3s/containerd/io.containerd.runtime.v2.task/k8s.io"' "${CONFIG_FILE}"
#yq e -i '.workspace.runtime.containerdSocket = "/run/k3s/containerd/containerd.sock"' "${CONFIG_FILE}"

# @todo(sje) remove mountPropagation == HostToContainer options
#installer render --config="${CONFIG_FILE}" --no-validation > gitpod.yaml

kubectl apply -f https://raw.githubusercontent.com/MrSimonEmms/gitpod-single-instance/develop/gitpod.yaml

success
