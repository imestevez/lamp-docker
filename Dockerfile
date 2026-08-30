FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        apache2 \
        libapache2-mod-php8.3 \
        php8.3 \
        php8.3-cli \
        php8.3-mysql \
        php8.3-mbstring \
        curl \
        ca-certificates \
    && rm -rf /var/lib/apt/lists/*

COPY docker/apache/000-default.conf \
    /etc/apache2/sites-available/000-default.conf

RUN a2enmod rewrite headers

EXPOSE 80

CMD ["apache2ctl", "-D", "FOREGROUND"]