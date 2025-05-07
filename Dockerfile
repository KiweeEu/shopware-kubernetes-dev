# syntax=docker/dockerfile:1

# Shopware-builder base image contains all necesary tools to build Shopware with `composer`.
FROM dunglas/frankenphp:1.4.4-php8.3.17-bookworm AS app-builder
ENV COMPOSER_HOME=/tmp/composer
ENV PROJECT_ROOT=/app
ENV UID=33
ENV GID=33

COPY --from=composer:2.8.6 /usr/bin/composer /usr/bin/composer
COPY php.ini.development /usr/local/etc/php/php.ini

RUN apt-get clean && apt-get update
RUN install-php-extensions \
	zip redis \
    && chown ${UID}:${GID} ${PROJECT_ROOT} \
    && rm -Rf ${PROJECT_ROOT}/* \
    && mkdir ${COMPOSER_HOME} \
    && chown ${UID}:${GID} ${COMPOSER_HOME}

USER www-data
COPY --chown=${UID}:${GID} composer.json composer.json
COPY --chown=${UID}:${GID} custom custom
COPY --chown=${UID}:${GID} config config
RUN mkdir -p custom/plugins

# Build application for production/pre-production - no debug tools.
FROM app-builder AS app-builder-prod
RUN --mount=type=secret,id=composer_auth,mode=444,dst=/app/auth.json \
    composer install --ignore-platform-reqs --no-dev --no-progress -a --apcu-autoloader --no-scripts

# Build dev application with dev dependencies
FROM app-builder AS app-builder-dev
RUN --mount=type=secret,id=composer_auth,mode=444,dst=/app/auth.json \
    composer install --ignore-platform-reqs --dev --no-progress --no-scripts \
    && echo '<?php phpinfo();' > public/info.php

# Build production static binary containing Shopware, PHP and Caddy webserver compiled-in.
FROM dunglas/frankenphp:static-builder-1.4.4 AS php-builder-prod
SHELL ["/bin/bash", "-c"]

# build-static.sh script compresses the executable with max compression level only which is too slow
# to be used in the CI. Thus the compression has been carried out of the build-static script,
# that's why the default compression must be turned off.
ENV NO_COMPRESS=1
# The List of extensions to build in.
ENV PHP_EXTENSIONS="amqp,apcu,bcmath,bz2,calendar,ctype,curl,dba,dom,exif,fileinfo,filter,gd,gmp,gettext,iconv,igbinary,intl,ldap,mbstring,mysqli,mysqlnd,opcache,openssl,opentelemetry,pcntl,pdo,pdo_mysql,pdo_sqlite,phar,posix,protobuf,readline,redis,session,shmop,simplexml,soap,sockets,sodium,sqlite3,ssh2,sysvmsg,sysvsem,sysvshm,tidy,tokenizer,xlswriter,xml,xmlreader,xmlwriter,zip,zlib,yaml,zstd"
ENV PHP_VERSION="8.3"
ARG PHP_STATIC_CLI_VERSION="2.4.5"

WORKDIR /go/src/app/dist/app
COPY --from=app-builder-prod /app /go/src/app/dist/app
COPY php.ini.production /go/src/app/dist/app/php.ini

WORKDIR /go/src/app/

# Before building the new php static binary
# ensure that the expected version of the static-php-cli is used instead of default one (dev-main).
RUN rm -Rf dist/static-php-cli dist/frankenphp-* \
    && git clone --depth 1 --branch ${PHP_STATIC_CLI_VERSION} --single-branch https://github.com/crazywhalecc/static-php-cli dist/static-php-cli \
    && EMBED=dist/app/ ./build-static.sh

# Compress the executable.
# Compression level=7 is a good balance between the compression ratio and speed.
RUN export BIN="frankenphp-"$(uname -s | tr '[:upper:]' '[:lower:]')"-"$(uname -m) \
    && upx -7 "dist/${BIN}" \
    && mv "dist/${BIN}" dist/shopware-bin

# Build an image containing the application binary only.
FROM debian:bookworm-slim AS app-prod
ENV UID=33
ENV GID=33

RUN apt update \
    && apt install -y jq ca-certificates \
    # create www-data user's homedir.
    && mkdir -p /var/www \
    && chown ${UID}:${GID} /var/www

COPY --from=php-builder-prod /go/src/app/dist/shopware-bin /shopware-bin

# php.ini to be loaded by php-cli
COPY --from=php-builder-prod /go/src/app/dist/app/php.ini /php.ini
USER ${UID}:${GID}
ENTRYPOINT ["/shopware-bin"]

# Build dev image with xdebug.
FROM dunglas/frankenphp:1.4.4-php8.3.17-bookworm AS app-dev
ENV PROJECT_ROOT=/app
ENV PHP_EXTENSIONS="amqp,apcu,bcmath,bz2,calendar,ctype,curl,dba,dom,exif,fileinfo,filter,gd,gmp,gettext,iconv,igbinary,intl,ldap,mbstring,mysqli,mysqlnd,opcache,openssl,opentelemetry,pcntl,pdo,pdo_mysql,pdo_sqlite,phar,posix,protobuf,readline,redis,session,shmop,simplexml,soap,sockets,sodium,sqlite3,ssh2,sysvmsg,sysvsem,sysvshm,tidy,tokenizer,xlswriter,xml,xmlreader,xmlwriter,zip,zlib,yaml,zstd"
ENV CADDY_GLOBAL_OPTIONS=debug
ENV UID=33
ENV GID=33
SHELL ["/bin/bash", "-c"]

COPY --from=composer:2.8.6 /usr/bin/composer /usr/bin/composer
COPY php.ini.development ${PHP_INI_DIR}/php.ini
COPY --chown=${UID}:${GID} --from=app-builder-dev ${PROJECT_ROOT} ${PROJECT_ROOT}

# Install all required prod & dev PHP extensions.
RUN apt update && apt install -y libxml2-dev libcurl4-openssl-dev jq \
    && REQUIRED_EXT=$(echo ${PHP_EXTENSIONS} | tr ',' '\n' | sort -u) \
    && INSTALLED_EXT=$(php -m | egrep -v '^\[.+\]$' | tr '[:upper:]' '[:lower:]' | sort -u) \
    # Select extensions which haven't been already installed.
    && EXT=$(comm -23 <(echo "${REQUIRED_EXT}") <(echo "${INSTALLED_EXT}") | tr '\n' ' ') \
    && install-php-extensions ${EXT} \
    && pecl install xdebug \
    && docker-php-ext-enable xdebug \
    && ln -s /usr/local/bin/frankenphp /shopware-bin \
    && mkdir -p /data/caddy/ \
    && chown ${UID}:${GID} /data/caddy/ \
    && chown ${UID}:${GID} ${PROJECT_ROOT}

WORKDIR ${PROJECT_ROOT}
USER ${UID}:${GID}
ENTRYPOINT ["/shopware-bin"]
