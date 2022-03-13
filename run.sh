#!/bin/bash

set -e

echo "Installing Gitpod for K3d"

k3d cluster delete gitpod

docker build -t k3s .

echo "Provision K3d"
k3d cluster create --config k3d-default.yaml

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
kubectl apply -f ./certificate.yaml

#kubectl apply -f ./out.yaml

gitpod-installer render -c config.yaml | kubectl apply -f -
