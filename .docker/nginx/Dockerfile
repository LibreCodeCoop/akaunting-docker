ARG NGINX_CONF=http
FROM nginx:alpine
ARG NGINX_CONF
ENV NGINX_PORT 80

# RUN echo "conf.d/${NGINX_CONF}.conf"

COPY "conf.d/${NGINX_CONF}.conf" /etc/nginx/templates/default.conf.template

WORKDIR /var/www/html