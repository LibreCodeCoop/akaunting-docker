ARG NGINX_CONF=http
# Pin the exact Nginx version and multi-platform digest for traceable Dependabot updates.
FROM nginx:1.31.6-alpine3.24@sha256:1ed1b0e1d7652937d6cbdaf4018c7b6fc009a7dd6c3047351e2eddda745de43f
ARG NGINX_CONF
ENV NGINX_PORT=80

COPY "conf.d/${NGINX_CONF}.conf" /etc/nginx/templates/default.conf.template

WORKDIR /var/www/html
