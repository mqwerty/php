FROM php:7.4-cli-alpine
EXPOSE 80 2113

RUN addgroup -S -g 3000 app && adduser --uid 3000 -G app -SDH app && mkdir /socks && chown app:app /socks

ARG DEPS="git"
RUN apk add --no-cache $DEPS

ARG DEPS_PHP="xdebug ast opcache"
ADD https://raw.githubusercontent.com/mlocati/docker-php-extension-installer/master/install-php-extensions /usr/local/bin/
RUN chmod u+x /usr/local/bin/install-php-extensions && sync && install-php-extensions $DEPS_PHP \
    && rm /usr/local/etc/php/conf.d/*xdebug.ini \
    && mv /usr/local/etc/php/php.ini-production /usr/local/etc/php/php.ini

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

COPY ./docker/app/conf/php/custom.ini /usr/local/etc/php/conf.d/

COPY ./docker/app/conf/rr/rr.yml /usr/local/etc/roadrunner/

RUN echo 'alias c="composer"' >> /root/.profile \
    && echo 'alias l="ls -lah"' >> /root/.profile

WORKDIR /app
COPY . .
RUN find /app -type d -print0 | xargs -t -0 -P 4 chmod 0755 > /dev/null 2>&1 \
    && find /app -type f -print0 | xargs -t -0 -P 4 chmod 0644 > /dev/null 2>&1

RUN composer install --no-cache --no-dev \
    && /app/vendor/bin/rr get-binary -l /usr/local/bin

ENTRYPOINT /usr/local/bin/rr serve -c /usr/local/etc/roadrunner/rr.yml
