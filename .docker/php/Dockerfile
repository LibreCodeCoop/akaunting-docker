# Build helpers are Docker dependencies so Dependabot can keep them current.
FROM composer:2.11.0@sha256:278dfc7bd35169965d03f87194816f43bf4e6b6ea61707c2114e52ad12fe24ce AS composer
FROM node:20.20.2-bookworm-slim@sha256:2cf067cfed83d5ea958367df9f966191a942351a2df77d6f0193e162b5febfc0 AS node
FROM mlocati/php-extension-installer:2.12.0 AS php-extension-installer
FROM php:8.3.36-fpm-trixie@sha256:7c6bba25ec696f21a2e3ca0b7d3e4282c899095e7e628c1851b0432f14a49d76 AS runtime

# Refresh kernel headers from Debian security fixes for CVE-2026-99083.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        git \
        linux-libc-dev \
        rsync \
        unzip \
    && rm -rf /var/lib/apt/lists/*

COPY --from=php-extension-installer /usr/bin/install-php-extensions /usr/local/bin/install-php-extensions
RUN install-php-extensions \
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

# Install Node.js from the pinned image and keep npm on a supported,
# security-patched release that is still compatible with Node 20.
COPY --from=node /usr/local/lib/node_modules /usr/local/lib/node_modules
COPY --from=node /usr/local/bin/node /usr/local/bin/node
# renovate: datasource=npm depName=npm
ARG NPM_VERSION=11.21.1
RUN ln -sf /usr/local/lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm \
    && ln -sf /usr/local/lib/node_modules/npm/bin/npx-cli.js /usr/local/bin/npx \
    && npm install --global "npm@${NPM_VERSION}" \
    && npm cache clean --force

COPY config/php.ini /usr/local/etc/php/conf.d/

WORKDIR /var/www/html
COPY php/wait-for-db.php /usr/local/bin/wait-for-db.php
COPY --chmod=0755 shell/apply-patches.sh /usr/local/bin/apply-patches.sh
COPY shell/lib/akaunting.sh /usr/local/lib/akaunting.sh
COPY --chmod=0755 shell/update-akaunting.sh /usr/local/bin/update-akaunting.sh
COPY --chmod=0755 shell/entrypoint.sh /usr/local/bin/entrypoint.sh
ENTRYPOINT ["bash", "/usr/local/bin/entrypoint.sh"]
