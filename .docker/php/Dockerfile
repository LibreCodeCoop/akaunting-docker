# Build helpers are Docker dependencies so Dependabot can keep them current.
FROM composer:2.10.3@sha256:af98f42dfff7c68ba8d53c2164fd9fde1087b7d449514baa38c418b1f6bc4bac AS composer
FROM node:20.20.2-bookworm-slim@sha256:2cf067cfed83d5ea958367df9f966191a942351a2df77d6f0193e162b5febfc0 AS node
FROM mlocati/php-extension-installer:2.12.0 AS php-extension-installer
FROM php:8.3.36-fpm-trixie AS runtime

# Stop builds before publication when upstream PHP still lacks the October 2026 RCE fixes.
# CVE-2026-109618 / CVE-2026-109619; unsupported PHP branches fail closed.
RUN php -r '$minimum = ["8.2" => "8.2.35", "8.3" => "8.3.36", "8.4" => "8.4.27", "8.5" => "8.5.12"]; $series = PHP_MAJOR_VERSION . "." . PHP_MINOR_VERSION; if (!isset($minimum[$series]) || version_compare(PHP_VERSION, $minimum[$series], "<")) { fwrite(STDERR, "Unpatched or unsupported PHP runtime: " . PHP_VERSION . PHP_EOL); exit(1); }'


RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        git \
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
ARG NPM_VERSION=11.21.0
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
