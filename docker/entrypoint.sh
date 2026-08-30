#!/bin/bash

set -e

mkdir -p /run/mysqld
chown -R mysql:mysql /run/mysqld /var/lib/mysql

FIRST_RUN=0

if [ ! -d /var/lib/mysql/mysql ]; then
    echo "Initializing MySQL database..."
    mysqld --initialize-insecure \
        --user=mysql \
        --datadir=/var/lib/mysql

    FIRST_RUN=1
fi

echo "Starting MySQL..."
mysqld \
    --user=mysql \
    --datadir=/var/lib/mysql &

MYSQL_PID=$!

echo "Waiting for MySQL..."

until mysqladmin ping --silent; do
    sleep 1
done

echo "MySQL is ready."

if [ "$FIRST_RUN" -eq 1 ]; then
    for sql in /docker-entrypoint-initdb.d/*.sql; do
        if [ -f "$sql" ]; then
            echo "Running $sql"
            mysql -uroot < "$sql"
        fi
    done
fi

echo "Starting Apache..."

apache2ctl -D FOREGROUND &

APACHE_PID=$!

trap 'kill -TERM "$MYSQL_PID" "$APACHE_PID" 2>/dev/null || true' TERM INT

wait -n "$MYSQL_PID" "$APACHE_PID"

STATUS=$?

kill -TERM "$MYSQL_PID" "$APACHE_PID" 2>/dev/null || true

wait || true

exit "$STATUS"