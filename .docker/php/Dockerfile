# Build helpers are Docker dependencies so Dependabot can keep them current.
FROM composer:2.11.1@sha256:8de2184c6de224f4689e8f80ed5f5edaf0030b6b8b7839a22a2bcb6722ac87d0 AS composer
FROM node:20.20.2-bookworm-slim@sha256:2cf067cfed83d5ea958367df9f966191a942351a2df77d6f0193e162b5febfc0 AS node
FROM mlocati/php-extension-installer:2.13.1@sha256:35821db0661308f64aa18483bb3af56bedc3b40090ff441ed961327d1ccbceb8 AS php-extension-installer
FROM php:8.3.36-fpm-trixie@sha256:03af352853b05e35ee15ab898a2755532573684c7d1120b246dbd4e3c90f5007 AS runtime

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
ARG NPM_VERSION=11.21.2
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
