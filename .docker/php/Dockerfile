# Build helpers are pinned to immutable image digests. Dependabot keeps the tags/digests updated.
FROM composer:2@sha256:4d71c3c2109c61d5415544264b59ad4087e4c5b7244481723664138fd36d5040 AS composer
FROM node:20-bookworm-slim@sha256:2cf067cfed83d5ea958367df9f966191a942351a2df77d6f0193e162b5febfc0 AS node
FROM php:8.3-fpm@sha256:e436b5b6ce4a4e632f97a66ea0ea14c5d001e229e2adc5c8ed2f7b5b5fe5c989 AS runtime

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        git \
        rsync \
        unzip \
    && rm -rf /var/lib/apt/lists/*

# Pin the installer release and verify the downloaded artifact before executing it.
ADD https://github.com/mlocati/docker-php-extension-installer/releases/download/2.12.0/install-php-extensions /usr/local/bin/install-php-extensions
RUN echo "3f49c71fa66c79b8b2b96bc0ce92885dafd7946f3b5a46f545b390d6f1617e2c  /usr/local/bin/install-php-extensions" | sha256sum -c - \
    && chmod uga+x /usr/local/bin/install-php-extensions \
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
    && chown -R www-data /var/www

COPY --from=composer /usr/bin/composer /usr/bin/composer

# Install Node.js and npm from the pinned Node image.
COPY --from=node /usr/local/lib/node_modules /usr/local/lib/node_modules
COPY --from=node /usr/local/bin/node /usr/local/bin/node
RUN ln -sf /usr/local/lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm \
    && ln -sf /usr/local/lib/node_modules/npm/bin/npx-cli.js /usr/local/bin/npx

COPY config/php.ini /usr/local/etc/php/conf.d/

WORKDIR /var/www/html
COPY wait-for-db.php /usr/local/bin/wait-for-db.php
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
ENTRYPOINT ["bash", "/usr/local/bin/entrypoint.sh"]
