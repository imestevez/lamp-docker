FROM imartinezestevez/lamp:latest

# Process-startup configuration.
COPY docker/apache/000-default.conf \
    /etc/apache2/sites-available/000-default.conf

COPY docker/php/99-development.ini \
     /etc/php/8.3/apache2/conf.d/99-development.ini

COPY docker/php/99-development.ini \
     /etc/php/8.3/cli/conf.d/99-development.ini

COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh

# Rewrite supports front controllers and REST routes; headers is commonly used
# by APIs and browser security policies.
RUN a2enmod rewrite headers \
    && chmod +x /usr/local/bin/entrypoint.sh

WORKDIR /var/www/html

EXPOSE 80

# The entrypoint supervises MySQL and Apache inside the same container.
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
