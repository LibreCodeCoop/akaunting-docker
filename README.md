# Akaunting with Docker

Running [Akaunting](https://github.com/akaunting/akaunting/) in a Docker container using `docker-compose`

Akaunting is a libre, open source and online accounting software designed for small businesses and freelancers. It is built with modern technologies such as Laravel, VueJS, Bootstrap 4, RESTful API etc. Thanks to its modular structure, Akaunting provides an awesome App Store for users and developers.

## Requirements

* Docker
* docker-compose

## Instalation

* Install Docker and docker-compose
* clone this repository
* copy `.env.example` to `.env`
* Update `AKAUNTING_VERSION` value to use the akaunting version of your preference. Get the latest version from https://github.com/akaunting/akaunting/releases/latest
* Fill other environments on blocks "`# Need to setup`"
* Run `docker-compose up`
* Access the application URL

## Development Overrides (Local only)

For local-only services and ports, use `docker-compose.override.yml` in your machine and do **not** commit this file.

Example:

```yaml
services:
  # Keep service names from docker-compose.yml and only override local behavior
  mailpit:
    image: axllent/mailpit:latest
    ports:
      - 127.0.0.1:8025:8025
      - 127.0.0.1:1025:1025

  openbao:
    image: openbao/openbao:latest
    command: server -dev
    environment:
      - BAO_DEV_ROOT_TOKEN_ID=${OPENBAO_DEV_TOKEN:-dev-only-root-token}
      - BAO_DEV_LISTEN_ADDRESS=0.0.0.0:8200
    cap_add:
      - IPC_LOCK
    ports:
      - 127.0.0.1:8200:8200
    healthcheck:
      test: ["CMD", "wget", "-qO-", "http://127.0.0.1:8200/v1/sys/health"]
      interval: 5s
      timeout: 3s
      retries: 12
      start_period: 5s

  # One-shot init: creates the 'nfse' KV v2 mount and enables AppRole auth.
  # Runs once after openbao is healthy; idempotent (|| true) so safe on restart.
  openbao-init:
    image: openbao/openbao:latest
    depends_on:
      openbao:
        condition: service_healthy
    environment:
      - BAO_ADDR=http://openbao:8200
      - BAO_TOKEN=${OPENBAO_DEV_TOKEN:-dev-only-root-token}
    command: >
      sh -c "
        bao secrets enable -path=nfse kv-v2 2>/dev/null || true &&
        bao auth enable approle 2>/dev/null || true &&
        echo 'OpenBao: mount nfse (kv-v2) e AppRole habilitados.'
      "
    restart: on-failure

  dufs:
    image: sigoden/dufs:latest
    command: /data -A --allow-upload --allow-delete
    volumes:
      - ./volumes/webdav:/data
    ports:
      - 127.0.0.1:5000:5000
```

> **PS**: After finish setup you will see two `.env` files: one on root of repository only used to setup Akaunting and other on `volumes/akaunting/.env`

If you need use a existing database, put your *.sql files on folder `volumes/mysql/dump`

The database will persisted on folder `volumes/mysql/data`

## Update

> Two files needed to be modified in production because Kimai is no longer a 100% open source project, be careful not to remove the changes made

* Go to the akaunting folder
  ```bash
  git pull origin main
  cd volumes/akaunting
  ```

* Get the latest version of akaunting and apply the required patches
  ```bash
  git pull origin master
  git apply ../../patches/akaunting-modifications.patch
  ```

* Execute the following commands, one by one, do not copy and paste all at once:
  ```bash
  docker compose exec php npm ci
  docker compose exec php npm run production
  docker compose exec php composer prod
  docker compose exec php php artisan update:all
  docker compose exec php php artisan cache:clear
  docker compose exec php php artisan optimize:clear
  docker compose exec php php artisan migrate
  chown -R www-data:www-data .
  ```

## Troubleshooting
* If you can't build the assets, copy the `volumes/akaunting/node_modules/` folder from another installation

## License

This project follows Akaunting licensing under the GPLv3 license.
