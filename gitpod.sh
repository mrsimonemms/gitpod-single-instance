#!/bin/bash

set -euo pipefail

CLUSTER_NAME="gitpod"
GITPOD_INSTALLER_VERSION="release-2022.04.1.2"

# Generic confirmation command
function _confirm() {
  text="${1}"
  args="${*:2}"

  if [[ "${args}" =~ (--yes)(\b|$) ]]; then
    # Skip interactive approval
    return
  fi

  while true; do
    read -r -p "${text}? [y/N] " yn
    case "${yn}" in
      [Yy]* ) break;;
      * ) exit;;
    esac
  done
}

# Generate help text for commands
function _help() {
  text="${1}"
  args="${*:2}"

  if [[ "${args}" =~ (--help|-h)(\b|$) ]]; then
    echo "${text}"
    exit
  fi
}

function _yq() {
  docker run -it --rm \
    -v "$(tmp_dir ""):/workdir" \
    mikefarah/yq \
    "$@"
}

function cert_manager() {
  echo "Provision cert-manger"

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
}

function check_dependencies() {
  echo "Checking dependencies"

  if ! command -v docker &> /dev/null; then
    echo "Docker could not be found - please visit https://docs.docker.com/get-docker for installation instructions"
    exit 1
  fi

  if ! command -v jq &> /dev/null; then
      echo "JQ could not be found - please visit https://stedolan.github.io/jq for installation instructions"
      exit 1
    fi

  if ! command -v k3d &> /dev/null; then
    echo "Installing k3d"
    wget -q -O - https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
  fi

  if ! command -v kubectl &> /dev/null; then
    echo "Installing Kubectl"
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    # shellcheck disable=SC2033
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    rm -f kubectl
  fi

  if ! command -v helm &> /dev/null; then
    echo "Installing Helm"
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
  fi
  echo "All dependencies available"
}

function load_file() {
  FILE_PATH="${1}"
  USE_LOCAL="${2}"
  BRANCH="${3}"

  if [[ "${USE_LOCAL}" == "true" ]]; then
    echo ".${FILE_PATH}"
  else
    mkdir -p "$(tmp_dir "/assets")"
    wget "https://raw.githubusercontent.com/MrSimonEmms/gitpod-single-instance/${BRANCH}/${FILE_PATH}" -O "$(tmp_dir "${FILE_PATH}")"
    tmp_dir "${FILE_PATH}"
  fi
}

function installer() {
  docker run -it --rm \
    -v="${KUBECONFIG}:${HOME}/.kube" \
    -v="$(tmp_dir ""):$(tmp_dir "")" \
    -v="${PWD}:${PWD}" \
    -w="${PWD}" \
    "eu.gcr.io/gitpod-core-dev/build/installer:${GITPOD_INSTALLER_VERSION}" \
    "${@}"
}

function provision_k3d() {
  echo "Provisioning k3d instance"

  CLUSTER=$(k3d cluster list -o json | jq -r --arg CLUSTER_NAME "${CLUSTER_NAME}" '.[] | select(.name == $CLUSTER_NAME)')

  if [[ "${CLUSTER}" == "" ]]; then
    touch /tmp/etc-hosts
    k3d cluster create --config "$(load_file "/assets/k3d.yaml" "${1}" "${2}")"
  fi

  KUBECONFIG="$(k3d kubeconfig write "${CLUSTER_NAME}")"
  export KUBECONFIG

  kubectl cluster-info
}

function tmp_dir() {
  # @todo(sje): make work cross-platform
  echo "/tmp${1}"
}

#################
# Public commands
#################

# shellcheck disable=SC2032
function install() {
  help=$(cat << EOF
Install a Gitpod instance to your local machine

Usage:
  install <branch>
Flags:
      --local           Use local files instead of branch. Useful for local development
  -h, --help            Display help
EOF
)
  _help "${help}" "${@}"

  USE_LOCAL=false
  if [[ "${*}" =~ (--local)(\b|$) ]]; then
    USE_LOCAL=true
  fi

  BRANCH="${1:-"main"}"

  check_dependencies
  provision_k3d "${USE_LOCAL}" "${BRANCH}"
  cert_manager

  CONFIG_FILE=$(tmp_dir "/gitpod-config.yaml")
  YQ_CONFIG_FILE="/workdir/gitpod-config.yaml"

  RENDER_FILE=$(tmp_dir "/gitpod.yaml")

  installer init > "${CONFIG_FILE}"

  echo "Edit the config file"

  _yq e -i '.domain = "localhost"' "${YQ_CONFIG_FILE}"
  _yq e -i '.workspace.runtime.containerdRuntimeDir = "/run/k3s/containerd/io.containerd.runtime.v2.task/k8s.io"' "${YQ_CONFIG_FILE}"
  _yq e -i '.workspace.runtime.containerdSocket = "/run/k3s/containerd/containerd.sock"' "${YQ_CONFIG_FILE}"
  _yq e -i '.customCACert.kind = "secret"' "${YQ_CONFIG_FILE}"
  _yq e -i '.customCACert.name = "ca-issuer-ca"' "${YQ_CONFIG_FILE}"

  installer render --config="${CONFIG_FILE}" --no-validation > "${RENDER_FILE}"

  echo "Post-process the rendered Kubernetes resources"

  # Remove any HostToContainer elements
  sed -i '/HostToContainer/d' "${RENDER_FILE}"

  echo "Apply the Kubernetes resources"
  kubectl apply -f "${RENDER_FILE}"

  echo "Create self-signed certificate"
  kubectl apply -f "$(load_file "/assets/certificate.yaml" "${USE_LOCAL}" "${BRANCH}")"

  echo "Get the CA certificate"
  CA_CERT=$(tmp_dir "/gitpod-ca.crt")
  kubectl get secret ca-issuer-ca -o jsonpath='{.data.ca\.crt}' | base64 -d > "${CA_CERT}"
}

function uninstall() {
  help=$(cat << EOF
Uninstall a Gitpod instance from your local machine
Flags:
      --yes         Skip interactive approval
  -h, --help        Display help
EOF
)
  _help "${help}" "${@}"

  _confirm "Are you sure you wish to uninstall Gitpod" "${@}"

  k3d cluster delete "${CLUSTER_NAME}"
}

function main() {
  case "${1}" in
    install) install "${*:2}";;
    uninstall) uninstall "${*:2}";;
    *)
      cat << EOF
Run Gitpod on your local machine

Usage:
  gitpod-single-instance [command]
Available commands:
  install             Install a Gitpod instance to your local machine
  uninstall           Uninstall a Gitpod instance from your local machine
Flags:
  -h, --help          Display help
EOF
    ;;
  esac
}

main "${@:-""}"
