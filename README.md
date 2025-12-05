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
