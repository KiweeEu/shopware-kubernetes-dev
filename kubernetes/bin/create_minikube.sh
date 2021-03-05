#!/usr/bin/env bash

OS_NAME=$(uname -s | tr A-Z a-z)

if [ "${OS_NAME}" == "darwin" ]; then
	VM="hyperkit"
elif [ "${OS_NAME}" == "linux" ]; then
	VM="kvm2"
else
	echo "Your operating system is not yet supported."
	exit 1
fi

minikube start \
	--kubernetes-version=v1.19.4 \
	--vm-driver=${VM} \
	--cpus=2 \
	--memory=6G \
	--disk-size=30G \
	--network-plugin=cni --cni=calico
	minikube addons enable default-storageclass
	minikube addons enable storage-provisioner
	minikube addons enable metrics-server

minikube dashboard --url