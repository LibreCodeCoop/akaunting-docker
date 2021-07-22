# Akaunting on Docker

Run [Akaunting](https://github.com/akaunting/akaunting/) on a Docker container using `docker-compose`

Akaunting is a libre, open source and online accounting software designed for small businesses and freelancers. It is built with modern technologies such as Laravel, VueJS, Bootstrap 4, RESTful API etc. Thanks to its modular structure, Akaunting provides an awesome App Store for users and developers.

## Requirements

* Docker
* docker-compose

## Instalation

* Install Docker and docker-compose
* clone this repository
* copy `.env.example` to `.env`
* Update `AKAUNTING_VERSION` value to use the akaunting version of your preference. Get the latest version from https://github.com/akaunting/akaunting/releases/latest
* Run `docker-compose up`
* Access the application URL
* After finish the setup of application, copy the file volumes/akaunting/.env to .env preserving important environments

## License

This project follow Akaunting licensing under the GPLv3 license.
