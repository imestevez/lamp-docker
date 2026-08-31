# Logs, verification and troubleshooting

This document contains the detailed commands used to inspect the LAMP-DOCKER environment when an application does not start or connect correctly.

## Check the Compose version first

```bash
docker compose version
```

This project requires Docker Compose v2. If only `docker-compose` 1.29.2 is
available, install the Compose plugin using the
[official Docker instructions](https://docs.docker.com/compose/install/).

A Python traceback mentioning `compose/cli/log_printer.py`, `watch_events` or
`event['id']` comes from the unmaintained Compose v1 client, not from Apache,
PHP, MySQL or the application. After installing Compose v2, use:

```bash
docker compose config
docker compose up -d
docker compose ps
```

## Buildx is not installed

Compose may display:

```text
WARN[0000] Docker Compose is configured to build using Bake, but buildx isn't installed
```

This concerns the image builder, not Apache, PHP, MySQL or the application.
Check whether Buildx is available:

```bash
docker buildx version
```

On Ubuntu 24.04 using Ubuntu's Docker packages, install it with:

```bash
sudo apt update
sudo apt install docker-buildx
```

If Docker Engine was installed from Docker's official APT repository, the
package is named `docker-buildx-plugin` instead:

```bash
sudo apt update
sudo apt install docker-buildx-plugin
```

Verify the installation and build again:

```bash
docker buildx version
docker compose up -d --build
```

Buildx includes the `docker buildx bake` command used by Compose. See the
[official Buildx reference](https://docs.docker.com/reference/cli/docker/buildx/)
and the [Docker Build overview](https://docs.docker.com/build/concepts/overview/).

## Logs

Apache writes its access log to standard output and its error log to standard error, so both are available through Docker Compose.

Recent logs:

```bash
docker compose logs --tail=100 lamp
```

Follow logs continuously:

```bash
docker compose logs -f lamp
```

These logs also show MySQL initialization messages from the container entrypoint.

## Basic container verification

Check the service state:

```bash
docker compose ps
```

Inspect running processes:

```bash
docker compose exec lamp ps aux
```

The container should contain both `mysqld` and Apache processes.

## Apache diagnostics

Check configuration syntax:

```bash
docker compose exec lamp apache2ctl -t
```

Expected:

```text
Syntax OK
```

Check version:

```bash
docker compose exec lamp apache2 -v
```

Check virtual hosts:

```bash
docker compose exec lamp apache2ctl -S
```

Check important modules.

### Linux

```bash
docker compose exec lamp apache2ctl -M | grep -E 'rewrite|headers'
```

### Windows PowerShell

```powershell
docker compose exec lamp apache2ctl -M |
    Select-String -Pattern 'rewrite|headers'
```

Test Apache from inside the container:

```bash
docker compose exec lamp curl -v http://127.0.0.1/
```

## PHP diagnostics

Check version:

```bash
docker compose exec lamp php -v
```

Check the required modules.

### Linux

```bash
docker compose exec lamp php -m | grep -E 'PDO|pdo_mysql|mysqli|mbstring'
```

### Windows PowerShell

```powershell
docker compose exec lamp php -m |
    Select-String -Pattern 'PDO|pdo_mysql|mysqli|mbstring'
```

Expected modules include:

```text
PDO
pdo_mysql
mysqli
mbstring
```

## MySQL diagnostics

Check version:

```bash
docker compose exec lamp mysql --version
```

Check whether the server is alive:

```bash
docker compose exec lamp mysqladmin -h 127.0.0.1 ping
```

Expected:

```text
mysqld is alive
```

## HTTP diagnostics

### Linux

```bash
curl -v http://localhost/
curl -v http://localhost/dbtest.php
```

### Windows PowerShell

```powershell
curl.exe -v http://localhost/
curl.exe -v http://localhost/dbtest.php
```

Use the configured `WEB_PORT` if it is not `80`.

---

## `.env` does not seem to be loaded

Compose must be run from the project root so that it finds `compose.yaml` and
loads the expected `.env` file.

The expected structure is:

```text
lamp-docker/
├── .env
├── compose.yaml
├── Dockerfile
├── db/
├── docker/
└── www/
```

Run Compose from the project root.

### Linux

```bash
cd /path/to/lamp-docker
ls -la .env compose.yaml
docker compose config
```

### Windows PowerShell

```powershell
Set-Location C:\path\to\lamp-docker
Get-Item .env, compose.yaml
docker compose config
```

Do not reset the database until `docker compose config` shows the expected values.

To inspect the database initialization mount:

### Linux

```bash
docker compose config | grep -B3 -A3 docker-entrypoint-initdb.d
```

### Windows PowerShell

```powershell
docker compose config |
    Select-String -Pattern "docker-entrypoint-initdb.d" -Context 3,3
```

---

## The wrong SQL initialization file is executed

Check:

```bash
docker compose logs lamp
```

If the log contains:

```text
Running /docker-entrypoint-initdb.d/01-test.sql
```

but another file was expected, check `DB_INIT_DIR` in `.env` and then run:

```bash
docker compose config
```

If MySQL has already created its volume, correcting `.env` alone is not enough.

If the current database may be deleted:

```bash
docker compose down -v
docker compose up -d
```

---

## `Access denied for user ...`

First test the application credentials directly inside the container:

```bash
docker compose exec lamp \
  mysql -h 127.0.0.1 -uUSERNAME -p DATABASE
```

Check:

1. that the selected SQL initialization file created the expected user;
2. that the password matches the application configuration;
3. that the user was granted privileges on the expected database;
4. that the correct initialization file actually ran.

Useful commands:

```bash
docker compose config
docker compose logs lamp
```

Do not use MySQL `root` as the normal database user of a PHP application.

---

## `Can't connect to local MySQL server through socket ...`

For example:

```text
ERROR 2002 (HY000): Can't connect to local MySQL server through socket ...
```

This commonly happens when the `mysql` client is executed on the host operating system rather than inside the LAMP container.

Incorrect for accessing the container database:

```bash
mysql -utswuser -p tswdb
```

Use:

```bash
docker compose exec lamp \
  mysql -h 127.0.0.1 -utswuser -p tswdb
```

---

## HTTP port already in use

Change:

```ini
WEB_PORT=80
```

to, for example:

```ini
WEB_PORT=8080
```

Restart:

```bash
docker compose down
docker compose up -d
```

Use:

```text
http://localhost:8080/
```

---

## Apache `AH00558` warning

Apache may report:

```text
AH00558: apache2: Could not reliably determine the server's fully qualified domain name...
```

This is a warning rather than an application-level PHP or MySQL error.

If `ServerName localhost` is configured globally, the warning should disappear.

---

## Diagnostic sequence

When an application does not work, use this order:

1. `docker compose config`
2. `docker compose ps`
3. `docker compose logs --tail=100 lamp`
4. `docker compose exec lamp apache2ctl -t`
5. `docker compose exec lamp mysqladmin -h 127.0.0.1 ping`
6. test the database credentials inside the container;
7. test `http://127.0.0.1/` from inside the container;
8. test `http://localhost/` from the host.

This order separates configuration, container, Apache, MySQL and host-networking problems.
