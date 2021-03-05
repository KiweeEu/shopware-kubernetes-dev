FROM webdevops/php-nginx-dev:7.4

ENV COMPOSER_HOME=/.composer
ENV NPM_CONFIG_CACHE=/.npm
ENV WEB_DOCUMENT_ROOT=/app/public
ENV PROJECT_ROOT=/app
ENV APP_URL=http://localhost:8000
ENV ENV_FILE=${PROJECT_ROOT}.env
ARG USER_ID=1000
ARG GROUP_ID=1000
ARG SHOPWARE_VERSION=6.3.5.1

RUN mkdir -p /usr/share/man/man1 \
    && curl -sL https://deb.nodesource.com/setup_12.x | bash \
    && mkdir -p ${NPM_CONFIG_CACHE} \
    && mkdir ${COMPOSER_HOME} \
    && chown ${USER_ID}:${GROUP_ID} ${COMPOSER_HOME} \
    && apt-install software-properties-common dirmngr nodejs libicu-dev graphviz vim gnupg2 \
    && npm i npm -g \
    && npm i forever -g \
    && chown -R ${USER_ID}:${GROUP_ID} ${NPM_CONFIG_CACHE} \
    && pecl install pcov-1.0.6 \
    && docker-php-ext-enable pcov \
    && apt-key adv --fetch-keys 'https://mariadb.org/mariadb_release_signing_key.asc' \
    && add-apt-repository 'deb [arch=amd64] https://ftp.icm.edu.pl/pub/unix/database/mariadb/repo/10.5/debian buster main' \
    && apt-install mariadb-client

COPY config/php/php-config.ini /usr/local/etc/php/conf.d/zzz-shopware.ini
COPY config/nginx/shopware.conf /opt/docker/etc/nginx/vhost.conf
COPY config/nginx/php.conf /opt/docker/etc/nginx/conf.d/10-php.conf
COPY config/php/php-fpm.conf /usr/local/etc/php-fpm.d/zzz-shopware.conf
COPY config/supervisord/administration-dev.conf /opt/docker/etc/supervisor.d/administration-dev.conf
COPY config/supervisord/shopware-init.conf /opt/docker/etc/supervisor.d/shopware-init.conf
COPY config/supervisord/storefront-dev.conf /opt/docker/etc/supervisor.d/storefront-dev.conf
COPY config/supervisord/group-dev.conf /opt/docker/etc/supervisor.d/group-dev.conf

# Update nginx user to match php-fpm and allow socket connection.
RUN sed -i 's/user www-data;/user application;/' /etc/nginx/nginx.conf

WORKDIR ${PROJECT_ROOT}
USER application

RUN composer create-project --no-interaction -- shopware/production . "${SHOPWARE_VERSION}"

COPY --chown=${USER_ID}:${GROUP_ID} config/shopware/storefront-watch.sh bin/storefront-watch.sh
COPY --chown=${USER_ID}:${GROUP_ID} config/shopware/administration-watch.sh bin/administration-watch.sh
COPY --chown=${USER_ID}:${GROUP_ID} config/shopware/plugins.json var/plugins.json
COPY --chown=${USER_ID}:${GROUP_ID} shopware/custom/plugins custom/plugins
COPY --chown=${USER_ID}:${GROUP_ID} config/shopware/wait-for-it.sh bin/wait-for-it.sh
COPY --chown=${USER_ID}:${GROUP_ID} config/shopware/shopware-init.sh bin/shopware-init.sh

# init storefront and administration
RUN npm clean-install --prefix vendor/shopware/administration/Resources/app/administration
RUN npm clean-install --prefix vendor/shopware/storefront/Resources/app/storefront/
RUN node vendor/shopware/storefront/Resources/app/storefront/copy-to-vendor.js

# build storefront
RUN npm --prefix vendor/shopware/storefront/Resources/app/storefront/ run production

# build adminstration
RUN npm run --prefix vendor/shopware/administration/Resources/app/administration/ build

ENTRYPOINT ["/entrypoint"]
CMD ["supervisord"]
