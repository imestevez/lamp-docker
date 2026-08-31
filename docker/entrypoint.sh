#!/usr/bin/env bash

set -Eeuo pipefail

MYSQL_PID=""
APACHE_PID=""

# Stop both managed services when either one exits or the container is stopped.
shutdown() {
    trap - EXIT TERM INT

    if [ -n "$APACHE_PID" ]; then
        kill -TERM "$APACHE_PID" 2>/dev/null || true
    fi

    if [ -n "$MYSQL_PID" ]; then
        kill -TERM "$MYSQL_PID" 2>/dev/null || true
    fi

    wait 2>/dev/null || true
}

trap shutdown EXIT
trap 'exit 143' TERM INT

mkdir -p /run/mysqld
chown -R mysql:mysql /run/mysqld /var/lib/mysql

FIRST_RUN=0
# These markers distinguish a completed setup from a partially executed SQL
# initialization. An interrupted setup must be reset instead of silently skipped.
INIT_STARTED=/var/lib/mysql/.lamp-docker-init-started
INIT_COMPLETE=/var/lib/mysql/.lamp-docker-init-complete

if [ ! -d /var/lib/mysql/mysql ]; then
    echo "Initializing MySQL database..."
    mysqld --initialize-insecure \
        --user=mysql \
        --datadir=/var/lib/mysql
    touch "$INIT_STARTED"
    FIRST_RUN=1
elif [ -e "$INIT_STARTED" ] && [ ! -e "$INIT_COMPLETE" ]; then
    echo "MySQL initialization was interrupted." >&2
    echo "Reset it with: docker compose down -v" >&2
    exit 1
fi

echo "Starting MySQL..."
mysqld \
    --user=mysql \
    --datadir=/var/lib/mysql &

MYSQL_PID=$!

echo "Waiting for MySQL..."

until mysqladmin ping --silent; do
    if ! kill -0 "$MYSQL_PID" 2>/dev/null; then
        echo "MySQL stopped before becoming ready." >&2
        exit 1
    fi

    sleep 1
done

echo "MySQL is ready."

if [ "$FIRST_RUN" -eq 1 ]; then
    # Shell glob expansion preserves lexical order (01-..., 02-..., etc.).
    for sql in /docker-entrypoint-initdb.d/*.sql; do
        if [ -f "$sql" ]; then
            echo "Running $sql"
            mysql -uroot < "$sql"
        fi
    done

    touch "$INIT_COMPLETE"
fi

echo "Starting Apache..."

apache2ctl -D FOREGROUND &

APACHE_PID=$!

set +e
# Preserve the exit status of the first service that stops. The EXIT trap then
# terminates the remaining service cleanly.
wait -n "$MYSQL_PID" "$APACHE_PID"
STATUS=$?
set -e

exit "$STATUS"
