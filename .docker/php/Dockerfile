FROM php:8.3-fpm

RUN apt-get update && apt-get install -y \
    git \
    rsync \
    unzip \
    --no-install-recommends

# Install PHP extensions
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
    xdebug \
    zip \
    && rm /usr/local/bin/install-php-extensions \
    # pevent errors when try to create files at /var/www with user www-data
    && chown -R www-data /var/www

COPY --from=composer /usr/bin/composer /usr/bin/composer

# Install Node.js and npm from official Node image
COPY --from=node:20-bookworm-slim /usr/local/lib/node_modules /usr/local/lib/node_modules
COPY --from=node:20-bookworm-slim /usr/local/bin/node /usr/local/bin/node
RUN ln -sf /usr/local/lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm \
    && ln -sf /usr/local/lib/node_modules/npm/bin/npx-cli.js /usr/local/bin/npx

COPY .docker/php/config/php.ini /usr/local/etc/php/conf.d/

WORKDIR /var/www/html
ARG AKAUNTING_VERSION=3.2.3
ENV AKAUNTING_VERSION=${AKAUNTING_VERSION}
COPY patches/akaunting-modifications.patch /tmp/akaunting-modifications.patch
COPY .docker/php/build-akaunting-app.sh /usr/local/bin/build-akaunting-app.sh
RUN bash /usr/local/bin/build-akaunting-app.sh \
    && rm -f /tmp/akaunting-modifications.patch /usr/local/bin/build-akaunting-app.sh \
    && rm -rf /var/www/html \
    && cp -a /opt/akaunting /var/www/html

COPY .docker/php/wait-for-db.php /usr/local/bin/wait-for-db.php
COPY .docker/php/entrypoint.sh /usr/local/bin/entrypoint.sh
ENTRYPOINT ["bash", "/usr/local/bin/entrypoint.sh"]
