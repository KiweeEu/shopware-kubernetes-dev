####################
# App Builder
####################
FROM kiweeteam/php-cli-shopware-builder:8.1-alpine3.15 AS builder

ENV COMPOSER_HOME=/.composer \
    APPLICATION_USER=www-data \
    APPLICATION_GROUP=www-data \
    APPLICATION_PATH=/app \
    APPLICATION_UID=82 \
    APPLICATION_GID=82 \
    PROJECT_ROOT=/app

ARG SHOPWARE_VERSION=6.4.11.1

RUN mkdir -p ${APPLICATION_PATH} && chown "${APPLICATION_USER}":"${APPLICATION_GROUP}" ${APPLICATION_PATH}
RUN apk update && apk add git

COPY config/supervisord/forward-newrelic-log.conf /opt/docker/etc/supervisor.d/forward-newrelic-log.conf
COPY config/supervisord/forward-newrelic-daemon-log.conf /opt/docker/etc/supervisor.d/forward-newrelic-daemon-log.conf

RUN mkdir -p /var/log/newrelic && chown ${APPLICATION_USER}:${APPLICATION_GROUP} /var/log/newrelic

WORKDIR ${PROJECT_ROOT}
USER ${APPLICATION_USER}

RUN composer create-project --no-interaction --no-scripts -- shopware/production . "${SHOPWARE_VERSION}"

RUN composer config --json extra.installer-types '["shopware-platform-plugin"]' \
    && composer config --json extra.installer-paths '{"custom/plugins/{$name}": ["type:shopware-platform-plugin"]}' \
    && composer config repositories.shopware '{"type": "composer", "url": "https://packages.shopware.com/"}'

COPY --chown=${APPLICATION_USER}:${APPLICATION_GROUP} shopware/custom/plugins custom/plugins
COPY --chown=${APPLICATION_USER}:${APPLICATION_GROUP} config/shopware/bootstrap.sh bin/bootstrap.sh
COPY --chown=${APPLICATION_USER}:${APPLICATION_GROUP} config/shopware/wait-for.sh bin/wait-for.sh
COPY --chown=${APPLICATION_USER}:${APPLICATION_GROUP} config/shopware/forward-app-log.sh bin/forward-app-log.sh
COPY --chown=${APPLICATION_USER}:${APPLICATION_GROUP} config/shopware/shopware-init.sh bin/shopware-init.sh
COPY --chown=${APPLICATION_USER}:${APPLICATION_GROUP} config/shopware/shopware-boot.sh bin/shopware-boot.sh
COPY --chown=${APPLICATION_USER}:${APPLICATION_GROUP} config/shopware/tasks-run.sh bin/tasks-run.sh
COPY --chown=${APPLICATION_USER}:${APPLICATION_GROUP} config/shopware/messenger-consume.sh bin/messenger-consume.sh
COPY --chown=${APPLICATION_USER}:${APPLICATION_GROUP} config/shopware/plugins.json var/plugins.json
COPY --chown=${APPLICATION_USER}:${APPLICATION_GROUP} patches/ patches/

RUN git apply patches/*.patch

####################
# App Server
####################
FROM kiweeteam/php-fpm:8.1-alpine3.15 AS web

ENV PROJECT_ROOT=/app
ENV APPLICATION_USER=www-data \
    APPLICATION_GROUP=www-data \
    APPLICATION_PATH=/app \
    APPLICATION_UID=82 \
    APPLICATION_GID=82 \
    NPM_CONFIG_CACHE=/.npm

RUN echo "Platform: $(uname -m)"

USER root

# workaround for new relic agent not available for ARM architecture
RUN if [ "$(uname -m)" == "x86_64" ]; then curl -L https://download.newrelic.com/php_agent/release/newrelic-php5-9.21.0.311-linux-musl.tar.gz | tar -C /tmp -zx \
   && NR_INSTALL_USE_CP_NOT_LN=1 NR_INSTALL_SILENT=1 /tmp/newrelic-php5-*/newrelic-install install \
   && rm -Rf /tmp/*; fi

RUN apk add --no-cache $PHPIZE_DEPS nodejs npm jq chromium chromium-chromedriver \
        && pecl install xdebug \
        && docker-php-ext-enable xdebug

RUN npm i npm -g \
      && npm i forever webpack-dev-server -g \
      && chown -R ${APPLICATION_USER}:${APPLICATION_GROUP} ${NPM_CONFIG_CACHE}

RUN set -e -o pipefail  \
    && curl -s https://getcomposer.org/installer | php \
    && mv ./composer.phar /usr/bin/composer

COPY config/php/xdebug.ini /usr/local/etc/php/conf.d/zz-xdebug-override.ini
COPY config/php/php-config.ini /usr/local/etc/php/conf.d/zzz-shopware.ini

RUN apk update && apk add mariadb-client
RUN mkdir ${PROJECT_ROOT} && chown ${APPLICATION_USER}:${APPLICATION_GROUP} ${PROJECT_ROOT}

COPY --from=builder /opt/docker/etc/supervisor.d/ /opt/docker/etc/supervisor.d/
# SHOPWARE_INIT=1 will ensure that the init script will be run on every container startup.
ENV SHOPWARE_INIT=1

USER ${APPLICATION_USER}
WORKDIR ${PROJECT_ROOT}

COPY --from=builder --chown=${APPLICATION_USER}:${APPLICATION_GROUP} ${PROJECT_ROOT} ${PROJECT_ROOT}

CMD ["/app/bin/bootstrap.sh"]

####################
# Job Scheduler
####################
FROM kiweeteam/php-cli:8.1-alpine3.15 AS job-scheduler

ENV PROJECT_ROOT=/app \
    APPLICATION_USER=www-data \
    APPLICATION_GROUP=www-data

RUN echo "Platform: $(uname -m)"
RUN apk update && apk add mariadb-client

# workaround for new relic agent not available for ARM64 architecture
RUN if [ "$(uname -m)" == "x86_64" ]; then curl -L https://download.newrelic.com/php_agent/release/newrelic-php5-9.21.0.311-linux-musl.tar.gz | tar -C /tmp -zx \
   && NR_INSTALL_USE_CP_NOT_LN=1 NR_INSTALL_SILENT=1 /tmp/newrelic-php5-*/newrelic-install install \
   && rm -Rf /tmp/*; fi

COPY config/php/php-config.ini /usr/local/etc/php/conf.d/zzz-shopware.ini
COPY config/supervisord/scheduled-tasks.conf /etc/supervisor.d/scheduled-tasks.conf
COPY --from=builder --chown=${APPLICATION_USER}:${APPLICATION_GROUP} ${PROJECT_ROOT} ${PROJECT_ROOT}
COPY --chown=${APPLICATION_USER}:${APPLICATION_GROUP} config/shopware/tasks-run.sh bin/tasks-run.sh

ENV SHOPWARE_INIT=0
USER ${APPLICATION_USER}
WORKDIR ${PROJECT_ROOT}

CMD ["/app/bin/bootstrap.sh"]

####################
# Message Consumer
####################
FROM job-scheduler AS message-consumer
ENV PROJECT_ROOT=/app \
    APPLICATION_USER=www-data \
    APPLICATION_GROUP=www-data
ARG PLATFORM=amd

RUN echo "Platform: $(uname -m)"

USER root
RUN rm -f /etc/supervisor.d/scheduled-tasks.conf
WORKDIR ${PROJECT_ROOT}
RUN rm -f bin/tasks-run.sh

ENV SHOPWARE_INIT=0
USER ${APPLICATION_USER}

COPY config/supervisord/message-consume.conf /etc/supervisor.d/message-consume.conf
COPY --chown=${APPLICATION_USER}:${APPLICATION_GROUP} config/shopware/messenger-consume.sh bin/messenger-consume.sh

FROM web AS cluster

ENV SHOPWARE_INIT=0
USER ${APPLICATION_USER}
