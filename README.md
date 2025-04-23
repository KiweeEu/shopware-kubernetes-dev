# Shopware on Kubernetes (Shopware-Kube)
This concept is to use Shopware app as a static executable binary on Kubernetes.
It is based on [FrankenPHP](https://frankenphp.dev) and [static-php-cli](https://static-php.dev) projects.
Note that a static binary is built for production environments only as xdebug won't work with a static binary. 
Therefore, the development version is based on `dunglas/frankenphp` container image instead.
Check out the article [Shopware on Kubernetes: build, test and debug](https://kiwee.eu/blog/shopware-6-development-on-kubernetes/) for more details.

## Build container images

### Build dev image
```shell
docker build --target=app-dev --progress=plain -t shopware-bin-dev .
```

### Build production image
```shell
docker build --target=app-prod --progress=plain -t shopware-bin .
```

## Start standalone container

### PHP Server
Production:
```shell
docker run --rm --name=shopware-bin -p 8000:8000 shopware-bin php-server -l 0.0.0.0:8000 -a -v --no-compress 
```
Development:
```shell
docker run --rm --name=shopware-bin -p 8000:8000 shopware-bin-dev php-server -l 0.0.0.0:8000 -a -v --no-compress 
```
### Run PHP-cli commands
```shell
docker run --rm --name=shopware-bin shopware-bin php-cli bin/console
```

## Requirements for Kubernetes cluster

Shopware cluster requires the following components to be available upfront in the cluster
* Ingress controller (e.g. NGINX Ingress Controller, Traefik or HAProxy).
* Object storage with S3 compatible API. In this example, we use [MinIO Operator](https://min.io/docs/minio/kubernetes/upstream/operations/installation.html).
* [Secret generator](https://github.com/mittwald/kubernetes-secret-generator) to automatically generate passwords.
* Optionally [Sealed secrets](https://github.com/bitnami-labs/sealed-secrets) to encrypt secrets that cannot be auto-generated, so they can be securely stored in the repository.

When deploying with Skaffold, the components listed above will be automatically installed.

## Create a local Minikube Kubernetes cluster
```shell
./create_cluster.sh
```

### Setup in-cluster test domains

Add two test domains into your hosts file, one for the application, the other for media object storage.

Mac OS
```shell
echo '127.0.0.1 media.test shopware.test' | sudo tee -a /etc/hosts
```

Linux
```shell
echo $(minikube ip)' media.test shopware.test' | sudo tee -a /etc/hosts
```

Get the minikube node IP address
```shell
minikube ip
```

Add .test domain into the CoreDNS config pasting the node IP address.
```shell
kubectl edit configmap coredns -n kube-system
```

Append the following into the `Corefile` and replace `192.168.49.2` with your actual IP address returned by `minikube ip`.
```
    test:53 {
        errors
        cache 30
        forward . 192.168.49.2
    }
```

## Build and run on Minikube using Skaffold
First delete shopware-init job if it exists
```shell
kubectl delete job/shopware-init -n shopware
```
To deploy and start the dev environment, run:
```shell
skaffold run --force=true -p dev
```
To deploy and start the production environment, run:
```shell
skaffold run --force=true -p production
```

## Access MinIO GUI
```shell
kubectl port-forward -n shopware pod/minio-shopware-pool0-0 9443:9443
```
The GUI is available at https://localhost:9443

The default username and password are: `minio:minio123`.

## Accessing Administration
The administration URL slug has a randomly generated suffix.
```shell
kubectl get secret/shopware-app-config -n shopware -o jsonpath='{.data.SHOPWARE_ADMINISTRATION_PATH_SUFFIX}' | \
base64 --decode; \
echo
```
Then paste the returned suffix into the following URL `http://shopware.test/admin_<SUFFIX>`.

## Open tunnel for storefront and media ingresses
It allows accessing Shopware from your host machine
(not needed on a Linux host).
```shell
minikube tunnel
```

## Reverse tunnel for Xdebug using ktunnel  

```shell
ktunnel inject deployment app-server-dev 9003
```

## Port forward shopware dev server
```shell
kubectl port-forward deploy/app-server-dev -n shopware 8000:8000
```
