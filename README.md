# Shopware-Kube

Shopware-Kube is a package of tools to create a dev cluster on Kubernetes for Shopware 6.
It allows hot code changes deployment without necessity of rebuilding the container image or even restarting the app server.
Another useful feature is debugger with xdebug 3. Tested on PhpStorm and IntelliJ with PHP plugin.
It is based on [Shopware/Production](https://github.com/shopware/production) template project, thus inherits all its tools.
It provides a configuration which is close to the production one but with extended debug features.
More explanation you will find in the article how to [develop Shopware 6 on Kubernetes](https://kiwee.eu/blog/shopware-6-development-on-kubernetes/).

## Prerequisites 
* Install [Minikube](https://minikube.sigs.k8s.io/docs/start/) for a local dev cluster
* For a remote cluster we recommend installing [MicroK8s](https://microk8s.io), but it should work with other distros too.
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
* If you have your custom `composer.json`, `composer.lock` or `auth.json` (to authenticate with the shopware store), copy these
  3 files into the directory `docker/shopware`. They are going to be used for the Shopware container image build.
  You can omit this step if you are starting the new project. Then the defaults are used.

### Deployment to remote cluster
* You need a container registry to push the app-server images to.
* Update `images.app-server.image` to match your container registry and image name. 
  Do not specify the tag as DevSpace generates own tags on each new build & push.
* Change `images.app-server.build.docker.skipPush` to `false`.

### Set current namespace
```
devspace use namespace development
```

### Deploy the configs and the elastic operators
```
kustomize build kubernetes/setup-only | kubectl apply -f -
```

## Build, deploy Shopware server and start development

To deploy for the first time and start development, just run:
```
devspace dev
```

The init scripts will automatically create a minimal configuration to be able to access the storefront and the administration.
Additionally, it will download `shopware/platform` with its dependencies locally for debugging.
The files are extracted into `docker/shopware/platform`. 

If you would like to enforce rebuilding the image, add the option `-b`.
```
devspace dev -b
```

If you'd like to override the default parameters (in `devspace.yaml`) follow the example below.
You can override all variables or just selected ones.
```
devspace dev -b --var=SHOPWARE_VERSION=6.4.0.0 --var=PHP_VERSION=7.4 --var=IMAGE_VERSION=alpine3.14 
```

### Access storefront and administration
The following URLs become available when `devspace dev` started up.

**NOTE**:
The storefront and the administration need to be built in dev mode first.
This is happening automatically on startup but may take a little while, depending on how fast the host machine is.
In case of running in a VM (Docker Desktop, Minikube) - how many resources are dedicated to it.

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