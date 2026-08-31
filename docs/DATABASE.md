# Database initialization and management

MySQL runs inside the same container as Apache and PHP.

PHP applications should normally connect using:

```text
host: 127.0.0.1
port: 3306
```

The MySQL port is not exposed to the host.

## Initialization directory

The directory selected by:

```ini
DB_INIT_DIR=...
```

is mounted as:

```text
/docker-entrypoint-initdb.d
```

When the MySQL volume is initialized for the first time, LAMP-DOCKER executes all `*.sql` files found directly in this directory, in alphabetical order.

Example:

```text
db/myproject/
├── 01-schema.sql
├── 02-data.sql
└── 03-extra.sql
```

These scripts are **initialization scripts, not migrations**.

Editing a SQL file after the volume has been initialized does not change the existing database.

## Database persistence

The MySQL files are stored in a Docker volume.

Stop the project while preserving its database:

```bash
docker compose down
```

Start it again:

```bash
docker compose up -d
```

The database remains unchanged.

## Reset the database

To delete the current database and initialize it again from the selected SQL files:

```bash
docker compose down -v
docker compose up -d
```

> **Warning:** `down -v` permanently deletes the MySQL data stored for the current Compose project.

Before doing this, verify the selected initialization directory:

```bash
docker compose config
```

Then check which SQL files were executed:

```bash
docker compose logs lamp
```

## Access MySQL

### Root account

Linux:

```bash
docker compose exec lamp mysql -uroot
```

Windows PowerShell:

```powershell
docker compose exec lamp mysql -uroot
```

The `root` account is intended for administration inside this development container. Applications should use their own database user instead.

## Access an application database

Example with the default test database:

```bash
docker compose exec lamp mysql -h 127.0.0.1 -utswuser -p tswdb
```

Enter:

```text
tswpass
```

when prompted.

## Verify a database and authenticated user

```bash
docker compose exec lamp \
  mysql -h 127.0.0.1 \
  -utswuser -ptswpass tswdb \
  -e "SELECT DATABASE(), CURRENT_USER();"
```

Expected result:

```text
+------------+-------------------+
| DATABASE() | CURRENT_USER()    |
+------------+-------------------+
| tswdb      | tswuser@localhost |
+------------+-------------------+
```

The MySQL client may display:

```text
[Warning] Using a password on the command line interface can be insecure.
```

This warning is expected when a password is supplied directly in a diagnostic command.

## List databases

```bash
docker compose exec lamp \
  mysql -h 127.0.0.1 \
  -utswuser -ptswpass \
  -e "SHOW DATABASES;"
```

A project user normally sees its own database plus MySQL metadata databases such as `information_schema` and `performance_schema`.

## Check that MySQL is running

```bash
docker compose exec lamp mysqladmin -h 127.0.0.1 ping
```

Expected output:

```text
mysqld is alive
```

## Load an SQL file manually

Initialization normally occurs automatically when a new volume is created.

For diagnostic or development purposes, an SQL file can also be loaded manually:

### Linux

```bash
docker compose exec -T lamp mysql -uroot < db/myproject/01-init.sql
```

### Windows PowerShell

PowerShell input redirection is different from a Unix shell. A portable option is:

```powershell
Get-Content .\db\myproject\01-init.sql -Raw |
    docker compose exec -T lamp mysql -uroot
```

Use manual loading carefully: unlike first-run initialization, it runs against the current database state.

## Application database users

Each application should normally have its own database and user:

```sql
CREATE DATABASE appdb;

CREATE USER 'appuser'@'localhost'
IDENTIFIED BY 'apppass';

GRANT ALL PRIVILEGES
ON appdb.*
TO 'appuser'@'localhost';

FLUSH PRIVILEGES;
```

Avoid using MySQL `root` from application PHP code.
