FROM php:7.4-fpm

RUN apt-get update && apt-get install -y \
    git \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libzip-dev \
    imagemagick \
    libmcrypt-dev \
    libpng-dev \
    libpq-dev \
    libxrender1 \
    locales \
    openssh-client \
    patch \
    rsync \
    unzip \
    zlib1g-dev \
    zip \
    --no-install-recommends && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

RUN docker-php-ext-configure gd --with-freetype --with-jpeg

RUN docker-php-ext-install \
    gd \
    bcmath \
    pcntl \
    pdo \
    pdo_pgsql \
    pdo_mysql \
    zip

COPY --from=composer /usr/bin/composer /usr/bin/composer

ENV NVM_DIR=/opt/nvm
RUN git clone https://github.com/nvm-sh/nvm.git $NVM_DIR
RUN cd $NVM_DIR && \
    git checkout `git describe --abbrev=0 --tags --match "v[0-9]*" $(git rev-list --tags --max-count=1)` && \
    . $NVM_DIR/nvm.sh && \
    nvm install 14 && \
    nvm use node && \
    npm install --global yarn
RUN echo "source ${NVM_DIR}/nvm.sh" > $HOME/.bashrc

WORKDIR /akaunting
COPY wait-for-db.php /usr/local/bin/wait-for-db.php
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
ENTRYPOINT ["sh", "/usr/local/bin/entrypoint.sh"]
