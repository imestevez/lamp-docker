FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# Install packages and OS clean data
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        apache2 \
        mysql-server \
        libapache2-mod-php8.3 \
        php8.3 \
        php8.3-cli \
        php8.3-mysql \
        php8.3-mbstring \
        curl \
        ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /var/lib/mysql/*

# Copy resources
COPY docker/apache/000-default.conf \
    /etc/apache2/sites-available/000-default.conf

COPY docker/php/99-development.ini \
     /etc/php/8.3/apache2/conf.d/99-development.ini

COPY docker/php/99-development.ini \
     /etc/php/8.3/cli/conf.d/99-development.ini

COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh

# Run commands
RUN a2enmod rewrite headers

RUN chmod +x /usr/local/bin/entrypoint.sh

# HTTP port
EXPOSE 80

# Initialize entrypoint script
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]