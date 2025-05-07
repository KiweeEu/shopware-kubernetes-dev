#!/usr/bin/env bash

VM=docker
CPUS=4
MEMORY=8G

minikube start \
	--kubernetes-version=v1.32.3 \
	--vm-driver=${VM} \
	--cpus=${CPUS} \
	--memory=${MEMORY} \
	--disk-size=30G \
	--network-plugin=cni --cni=calico
	minikube addons enable default-storageclass
	minikube addons enable storage-provisioner
	minikube addons enable metrics-server
  minikube addons enable ingress
  minikube addons enable ingress-dns
