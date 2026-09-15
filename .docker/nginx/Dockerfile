ARG NGINX_CONF=http
FROM php:8.3-cli AS app
ARG AKAUNTING_VERSION=3.2.3

RUN apt-get update && apt-get install -y \
    git \
    rsync \
    unzip \
    --no-install-recommends

ADD https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/
RUN chmod uga+x /usr/local/bin/install-php-extensions && sync \
    && install-php-extensions \
    apcu \
    bcmath \
    gd \
    gmp \
    exif \
    imagick \
    intl \
    memcached \
    mysqli \
    opcache \
    pcntl \
    pdo \
    pdo_mysql \
    pdo_pgsql \
    pgsql \
    redis \
    soap \
    sockets \
    sysvsem \
    zip \
    && rm /usr/local/bin/install-php-extensions

COPY --from=composer /usr/bin/composer /usr/bin/composer
COPY --from=node:20-bookworm-slim /usr/local/lib/node_modules /usr/local/lib/node_modules
COPY --from=node:20-bookworm-slim /usr/local/bin/node /usr/local/bin/node
RUN ln -sf /usr/local/lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm \
    && ln -sf /usr/local/lib/node_modules/npm/bin/npx-cli.js /usr/local/bin/npx

COPY patches/akaunting-modifications.patch /tmp/akaunting-modifications.patch
COPY .docker/php/build-akaunting-app.sh /usr/local/bin/build-akaunting-app.sh
RUN bash /usr/local/bin/build-akaunting-app.sh \
    && rm -f /tmp/akaunting-modifications.patch /usr/local/bin/build-akaunting-app.sh

FROM nginx:alpine
ARG NGINX_CONF
ENV NGINX_PORT 80

# RUN echo "conf.d/${NGINX_CONF}.conf"

COPY ".docker/nginx/conf.d/${NGINX_CONF}.conf" /etc/nginx/templates/default.conf.template

WORKDIR /var/www/html
COPY --from=app /opt/akaunting /var/www/html
RUN mkdir -p /var/www/akaunting-data/storage /var/www/akaunting-data/bootstrap/cache /var/www/akaunting-data/modules \
    && cp -a /var/www/html/modules/. /var/www/akaunting-data/modules/ \
    && rm -rf /var/www/html/storage /var/www/html/bootstrap/cache /var/www/html/modules \
    && ln -s /var/www/akaunting-data/storage /var/www/html/storage \
    && ln -s /var/www/akaunting-data/bootstrap/cache /var/www/html/bootstrap/cache \
    && ln -s /var/www/akaunting-data/modules /var/www/html/modules
