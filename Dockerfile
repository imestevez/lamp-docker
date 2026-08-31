FROM ubuntu:24.04

# Prevent package installation from requesting interactive input during builds.
ENV DEBIAN_FRONTEND=noninteractive

# Install the complete LAMP stack and remove caches and the database created by
# the package installer. MySQL is initialized later in the persistent volume.
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

# Install project-specific Apache, PHP and process-startup configuration.
COPY docker/apache/000-default.conf \
    /etc/apache2/sites-available/000-default.conf

COPY docker/php/99-development.ini \
     /etc/php/8.3/apache2/conf.d/99-development.ini

COPY docker/php/99-development.ini \
     /etc/php/8.3/cli/conf.d/99-development.ini

COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh

# rewrite supports front controllers and REST routes; headers is commonly used
# by APIs and browser security policies.
RUN a2enmod rewrite headers \
    && chmod +x /usr/local/bin/entrypoint.sh

WORKDIR /var/www/html

EXPOSE 80

# The entrypoint supervises MySQL and Apache inside the same container.
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
