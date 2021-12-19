#!/bin/bash

set -e

echo "Installing Gitpod for K3d"

k3d cluster delete gitpod

#docker build -t k3s .

#sudo kill -9 `sudo lsof -t -i:8080` || true
#sudo kill -9 `sudo lsof -t -i:8443` || true
#sudo kill -9 `sudo lsof -t -i:9500` || true

echo "Provision K3d"
k3d cluster create --config k3d.yaml || true

export KUBECONFIG="$(k3d kubeconfig write gitpod || true)"

sleep 10

echo "Updating helm repositories..."
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo add jetstack https://charts.jetstack.io
helm repo update

echo "Installing cert-manager..."
helm upgrade \
    --atomic \
    --cleanup-on-fail \
    --create-namespace \
    --install \
    --namespace cert-manager \
    --reset-values \
    --set installCRDs=true \
    --values=./cert-manager-values.yaml \
    --wait \
    cert-manager \
    jetstack/cert-manager

echo "Create certificates..."
kubectl apply -f ./certificate.yaml

kubectl apply -f ./out.yaml
