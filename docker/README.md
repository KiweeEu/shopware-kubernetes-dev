# Shopware 6 Docker Image

## Build for docker only

```bash
SHOPWARE_VERSION=6.4.11.1 && \
BUILD_ID=1 && \
docker build --progress=plain --build-arg=SHOPWARE_VERSION=$SHOPWARE_VERSION --target=web --compress --rm -t kiweeteam/shopware6:${SHOPWARE_VERSION}-w${BUILD_ID} . && \
docker build --progress=plain --build-arg=SHOPWARE_VERSION=$SHOPWARE_VERSION --target=job-scheduler --compress --rm -t kiweeteam/shopware6:${SHOPWARE_VERSION}-js${BUILD_ID} . && \
docker build --progress=plain --build-arg=SHOPWARE_VERSION=$SHOPWARE_VERSION --target=message-consumer --compress --rm -t kiweeteam/shopware6:${SHOPWARE_VERSION}-mc${BUILD_ID} .
```

## Build app-server optimized for a K8S cluster
```bash
docker build --progress=plain --build-arg=SHOPWARE_VERSION=$SHOPWARE_VERSION --target=cluster --compress --rm -t kiweeteam/shopware6:${SHOPWARE_VERSION}-c${BUILD_ID} .
```

## Build for ARM64 architecture
* Use `docker buildx build` command.
* Use additional parameters for the build command: `--platform=linux/arm64/v8`

## Push for docker only
```bash
BUILD_ID=1 && \
docker push kiweeteam/shopware6:${SHOPWARE_VERSION}-w${BUILD_ID} && \
docker push kiweeteam/shopware6:${SHOPWARE_VERSION}-js${BUILD_ID} && \
docker push kiweeteam/shopware6:${SHOPWARE_VERSION}-mc${BUILD_ID}
```

## Push for the cluster
```bash
docker push kiweeteam/shopware6:${SHOPWARE_VERSION}-c${BUILD_ID}
```
