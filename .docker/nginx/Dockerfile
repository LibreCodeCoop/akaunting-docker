ARG NGINX_CONF=http
# Pin the exact Nginx version and multi-platform digest for traceable Dependabot updates.
FROM nginx:1.31.7-alpine3.24@sha256:892bb2152464f0c5d8972593a5f5afaf8054552580b699d95f8ff4af08c2d33d
ARG NGINX_CONF
ENV NGINX_PORT=80

COPY "conf.d/${NGINX_CONF}.conf" /etc/nginx/templates/default.conf.template

WORKDIR /var/www/html
