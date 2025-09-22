# Akaunting with Docker

Running [Akaunting](https://github.com/akaunting/akaunting/) in a Docker container using `docker compose`

Akaunting is a libre, open source and online accounting software designed for small businesses and freelancers. It is built with modern technologies such as Laravel, VueJS, Bootstrap 4, RESTful API etc. Thanks to its modular structure, Akaunting provides an awesome App Store for users and developers.

## Requirements

* Docker
* docker compose plugin

## Instalation

* Install Docker and docker-compose
* clone this repository
* copy `.env.example` to `.env`
* Update `AKAUNTING_VERSION` value to use the akaunting version of your preference. Get the latest version from https://github.com/akaunting/akaunting/releases/latest
* Fill other environments on blocks "`# Need to setup`"
* Run `docker compose up`
* Access the application URL

> **PS**: After finish setup you will see two `.env` files: one on root of repository only used to setup Akaunting and other on `volumes/akaunting/.env`

If you need use a existing database, put your *.sql files on folder `volumes/mysql/dump`

The database will persisted on folder `volumes/mysql/data`

## License

This project follows Akaunting licensing under the GPLv3 license.
