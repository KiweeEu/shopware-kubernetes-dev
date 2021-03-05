# Shopware-Kube

Shopware-Kube is a package of tools to create a dev cluster on Kubernetes for Shopware 6.
It allows hot code changes deployment without necessity of rebuilding the container image or even restarting the app server.
Another useful feature is debugger with xdebug 3. Tested on PhpStorm and IntelliJ with PHP plugin.
It is based on [Shopware/Production](https://github.com/shopware/production) template project, thus inherits all its tools.
It provides a configuration which is close to the production one but with extended debug features.

## Prerequisites 
* Install [Minikube](https://minikube.sigs.k8s.io/docs/start/) for a local dev cluster
* For a remote cluster we recommend installing [MicroK8s](https://microk8s.io).
* Install [DevSpace](https://devspace.sh/cli/docs/getting-started/installation).
* Install [Kustomize](https://kubectl.docs.kubernetes.io/installation/kustomize/)


## Cluster creation
In case of a local Minikube: create a cluster:
```
./kubernetes/bin/create_minikube.sh
```

For MicroK8s follow this [setup tutorial](https://ubuntu.com/tutorials/install-a-local-kubernetes-with-microk8s?&_ga=2.181492961.777099064.1610383197-667444104.1610383197#2-deploying-microk8s),
and install the following 2 additional addons:
```
microk8s enable storage
microk8s enable dns
```

You may need to increase `max_user_watches` limit. 
For Minikube run:
```
minikube ssh
```
Check the current value by:
```
sysctl fs.inotify.max_user_watches
```
If it's the default value `8192` you may experience running out of watches after starting the dev servers.
Here's how to update it.
```
sudo sysctl -w fs.inotify.max_user_watches=65536
```
If you installed Kubernetes on a remote machine you can persist this setting by:
```
echo 'fs.inotify.max_user_watches=65536' | sudo tee /etc/sysctl.d/20-watches.conf
```

## First time deployment preparation
* Copy `devspace.yaml.dist` to `devspace.yaml`
* Edit `devspace.yaml` and provide the actual container image name into `images.app-server.image` field.
* Copy `kubernetes/config/.env.dist` to `kubernetes/config/.env` and adjust it if necessary.   
* Optionally, update `SHOPWARE_VERSION` if you wish to build a different Shopware version.
* For Minikube, a recommended setting is `skipPush: true`. DevSpace won't push images to the container registry then. 
  Locally the image is accessible via the local Docker daemon.
  This speeds up deployments significantly. You will find this setting in `devspace.yaml` at `images.app-server.image.docker`.

### Deployment to remote cluster
* You need a container registry to push the app-server images to.
* Update `images.app-server.image` to match your container registry and image name. 
  Do not specify the tag as DevSpace generates own tags on each new build & push.
* Change `images.app-server.build.docker.skipPush` to `false`.

### Deploy the configs and the elastic operators
```
kustomize build kubernetes/setup-only | kubectl apply -f -
```

## Build, deploy Shopware server and start development

Set `development` as the current namespace:
```
devspace use namespace development
```

To deploy for the first time and start development, just run:
```
devspace dev
```

The init scripts will automatically create a minimal configuration to be able to access the storefront and the administration.
Additionally, it will download `shopware/platform` with its dependencies locally for debugging.
The files are extracted into `docker/shopware/platform` and `docker/shopware/vendor`.

If you would like to enforce rebuilding the image, add the option `-b`.
```
devspace dev -b
```

If you'd like to override the default SHOPWARE_VERSION parameter (in `devspace.yaml`) follow this example:
```
devspace dev -b --var=SHOPWARE_VERSION=6.3.5.1
```

### Access storefront and administration
The following URLs become available when `devspace dev` started up:

- Storefront with HMR and Xdebug enabled: [http://localhost:9998/](http://localhost:9998/)
- Storefront with Xdebug: [http://localhost:8000/](http://localhost:8000/) - 
- Administration with HMR and Xdebug enabled: [http://localhost:8080/](http://localhost:8080/)
- Administration with Xdebug: [http://localhost:8000/admin/](http://localhost:8000/admin/)

### Adminer
Adminer becomes available at [http://localhost:8081/](http://localhost:8081/).

### MailHog
MailHog UI available at: [http://localhost:8025](http://localhost:8025).

The initial admin user is `admin:shopware`.

### Development
The work directory for new plugins and themes is `docker/shopware/custom/plugins`.

## Cleanup
### Local Minikube

```
minikube delete
```
It deletes all traces of the cluster, including the storage.

### MicroK8s
In case of remote MicroK8s, run on the master node

```
microk8s reset [--destroy-storage]
```
Adding `--destroy-storage` will remove the persistent volumes too.