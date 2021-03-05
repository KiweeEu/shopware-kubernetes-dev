# Shopware-Kube Container Build


## Contents

* `Dockerfile` 
* `config/nginx/*` - NGINX vhost and php-fpm config.
* `config/php/php-config.ini` - Shopware specific php settings.
* `config/php/pfp-fpm.conf` - To use UNIX socket since NGINX and PHP-FPM run in a single container.
* `config/shopware/*.sh` - Tools which are executed on container startup.
* `config/shopware/plugins.json` - paths to the core modules which are required to build the storefront and administration.
* `config/supervisord/*.conf` - supervisord config files to run the init script, storefront-watch and administration-watch servers. 
* `shopware/custom/plugins/` - placeholder directory for custom plugins

## Build
```
docker build -t imagename:latest .
```