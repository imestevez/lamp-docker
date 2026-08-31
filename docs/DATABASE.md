# Database initialization and management

MySQL runs inside the same container as Apache and PHP.

When adding a project, start with
[Adding and deploying projects](PROJECTS.md#adding-and-deploying-projects).
This document explains the database lifecycle and the less common database
operations in more detail.

## Shared vs isolated databases

Both workflows use `DB_INIT_DIR`; what changes is the selected directory and
the volume that stores the live data.

| Shared base environment | Isolated project deployment |
| --- | --- |
| Uses `.env` and the shared `lamp` volume | Uses `.env.<project>` and its own volume |
| Usually `DB_INIT_DIR=./db/init` | Usually `DB_INIT_DIR=./db/<project>` |
| Later databases should normally be imported manually | The project volume can be recreated independently |

## The database lifecycle

LAMP-DOCKER separates the SQL files stored on the host from the live database:

```text
DB_INIT_DIR/*.sql
        |
        | first creation only
        v
Docker MySQL volume
        |
        | used on every later start
        v
live database
```

The SQL files describe how to create a fresh database. The Docker volume holds
the database that PHP is actually using.

Consequently:

> Editing an initialization SQL file does not update an existing live database.

## Command convention

The examples below use the shared base environment:

```bash
docker compose COMMAND
```

For an isolated project, use its environment file in every command:

```bash
docker compose --env-file .env.myproject1 COMMAND
```

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

When the MySQL volume is initialized for the first time, LAMP-DOCKER executes
all `*.sql` files found directly in this directory, in alphabetical order.

For example, an isolated project may use:

```text
db/myproject/
├── 01-schema.sql
├── 02-data.sql
└── 03-extra.sql
```

These scripts are **initialization scripts, not migrations**.

In practice:

- before the first start, edit the files in `DB_INIT_DIR`;
- after the first start, apply the required SQL change manually or use the
  application's migration mechanism if it provides one;
- use `down -v` only during development when the current database data may be
  deleted and recreated.

## What should I do after a change?

| What changed? | Action |
| --- | --- |
| PHP, HTML, CSS or JavaScript | Reload the page |
| `APP_DIR` or `WEB_PORT` | Run `down`, then `up -d` |
| `Dockerfile` or files under `docker/` | Run `up -d --build` |
| SQL before the volume exists | Start normally; initialization runs once |
| SQL after the volume exists, keeping its data | Apply the SQL manually or use the application's migration mechanism |
| SQL after the volume exists, discarding its data | Run `down -v`, then `up -d` |
| Data created by the application | Nothing; it persists in the volume |

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

For an isolated deployment, use the same environment file in both commands:

```bash
docker compose --env-file .env.myproject1 down
docker compose --env-file .env.myproject1 up -d
```

## Reset the database

To delete the current database and initialize it again from the selected SQL
files:

Shared base environment:

```bash
docker compose config
docker compose down -v
docker compose up -d
```

Isolated project:

```bash
docker compose --env-file .env.myproject1 config
docker compose --env-file .env.myproject1 down -v
docker compose --env-file .env.myproject1 up -d
```

> **Warning:** `down -v` permanently deletes the MySQL data stored for the
> selected Compose project.

Always check `config` before resetting a database.

Then check which SQL files were executed:

```bash
docker compose logs lamp
```

or, for an isolated project:

```bash
docker compose --env-file .env.myproject1 logs lamp
```

## Access MySQL

### Root account

Shared environment:

```bash
docker compose exec lamp mysql -uroot
```

Isolated project:

```bash
docker compose --env-file .env.myproject1 exec lamp mysql -uroot
```

The `root` account is intended for administration inside this development
container. Applications should use their own database user instead.

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

For an isolated application, use its environment file and credentials:

```bash
docker compose --env-file .env.myproject1 exec lamp \
    mysql -h 127.0.0.1 -uUSERNAME -p DATABASE
```

## Verify a database and authenticated user

Default test database:

```bash
docker compose exec lamp \
    mysql -h 127.0.0.1 -utswuser -ptswpass tswdb \
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

This warning is expected when a password is supplied directly in a diagnostic
command.

## List databases

```bash
docker compose exec lamp \
    mysql -h 127.0.0.1 -utswuser -ptswpass \
    -e "SHOW DATABASES;"
```

A project user normally sees its own database plus MySQL metadata databases such
as `information_schema` and `performance_schema`.

## Check that MySQL is running

```bash
docker compose exec lamp mysqladmin -h 127.0.0.1 ping
```

Expected output:

```text
mysqld is alive
```

For an isolated project:

```bash
docker compose --env-file .env.myproject1 exec lamp \
    mysqladmin -h 127.0.0.1 ping
```

## Load an SQL file manually

Initialization normally occurs automatically when a new volume is created.

Manual loading is useful when adding a database to an already initialized
shared environment or when intentionally applying SQL to a live database.

### Linux

```bash
docker compose exec -T lamp mysql -uroot < db/myproject/01-init.sql
```

### Windows PowerShell

```powershell
Get-Content .\db\myproject\01-init.sql -Raw |
    docker compose exec -T lamp mysql -uroot
```

Use manual loading carefully: unlike first-run initialization, it runs against
the current database state.

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

## Important: `DB_INIT_DIR` does not select a live database

Changing:

```ini
DB_INIT_DIR=./db/project-a
```

to:

```ini
DB_INIT_DIR=./db/project-b
```

does not replace an already initialized MySQL volume.

`DB_INIT_DIR` only selects the SQL files that should be used **when a fresh
MySQL volume is created**.
