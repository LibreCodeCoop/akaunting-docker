ARG NGINX_CONF=http
# Pin the exact Nginx version and multi-platform digest for traceable Dependabot updates.
FROM nginx:1.31.8-alpine3.24@sha256:fed7e14be83cbd2661a75cdc5b872d936cf155d46c327084d30b8df19ae88d72
# The pinned upstream image still contains brotli-libs 1.2.0-r1 (CVE-2026-111497).
# Apply Alpine's fixed package without disabling vulnerability scanning.
RUN apk upgrade --no-cache brotli-libs

ARG NGINX_CONF
ENV NGINX_PORT=80

COPY "conf.d/${NGINX_CONF}.conf" /etc/nginx/templates/default.conf.template

WORKDIR /var/www/html
