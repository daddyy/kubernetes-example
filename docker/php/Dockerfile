FROM composer:latest as vendor
COPY ./app/composer.json ./app/composer.lock /app/
# --no-dev -> není potřeba pokud používám v rámci tohoto z envu COMPOSE_NO_DEV
RUN composer install --no-dev --optimize-autoloader --ignore-platform-reqs --working-dir=/app

FROM php:8.1-fpm-alpine

RUN apk add \
    icu-dev \
    gettext \
    gettext-dev \
    && docker-php-ext-install \
    pdo \
    pdo_mysql \
    intl \
    gettext

COPY ./docker/php/default.conf /etc/php/8.1/fpm/pool.d/default.conf
COPY ./docker/php/php.ini /etc/php/8.1/fpm/php.ini
# není to zde zbytčné? pokud již kopírují o řádek níže?, není vše v jendom adresáři
COPY ./app/ /var/www/html/
COPY --from=vendor /app/vendor /var/www/html/vendor

COPY ./docker/php/bin/docker-php-fpm.sh /usr/local/bin/docker-php-fpm.sh
RUN chmod +x /usr/local/bin/docker-php-fpm.sh

# HEALTHCHECK --interval=15s --timeout=15s CMD /usr/local/bin/docker-php-fpm.sh 15 || exit 1

# CMD ["/usr/sbin/php-fpm8.1 -R --nodaemonize --fpm-config /etc/php/8.1/fpm/php-fpm.conf"]