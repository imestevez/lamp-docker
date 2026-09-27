# Logs, verification and troubleshooting

When an application does not work, start with these three commands instead of
changing configuration at random:

```bash
docker compose config
docker compose ps
docker compose logs --tail=100 lamp
```

| Command | Question it answers |
| --- | --- |
| `docker compose config` | Which paths, port and project name will Compose use? |
| `docker compose ps` | Is the container running and healthy? |
| `docker compose logs ...` | What happened during MySQL/Apache startup and requests? |

The examples below use the shared base environment.

For an isolated project, use the same environment file that was used to start
it:

```bash
docker compose --env-file .env.myproject1 config
docker compose --env-file .env.myproject1 ps
docker compose --env-file .env.myproject1 logs --tail=100 lamp
```

> Mixing commands with and without `--env-file` can inspect, stop or reset the
> wrong container and database volume.

---

## Common problems

### `.env` does not seem to be loaded

Compose must be run from the project root so that it finds `compose.yaml` and
loads the expected `.env` file.

Expected structure:

```text
lamp-docker/
├── .env
├── compose.yaml
├── Dockerfile
├── db/
├── docker/
└── www/
```

**Linux:**

```bash
cd /path/to/lamp-docker
ls -la .env compose.yaml
docker compose config
```

**Windows PowerShell:**

```powershell
Set-Location C:\path\to\lamp-docker
Get-Item .env, compose.yaml
docker compose config
```

For an isolated deployment, explicitly select its environment file:

```bash
docker compose --env-file .env.myproject1 config
```

Do not reset a database until `config` shows the expected values.

To inspect the database initialization mount:

**Linux:**

```bash
docker compose config | grep -B3 -A3 docker-entrypoint-initdb.d
```

**Windows PowerShell:**

```powershell
docker compose config |
    Select-String -Pattern "docker-entrypoint-initdb.d" -Context 3,3
```

### The wrong SQL initialization file is executed

Check the logs:

```bash
docker compose logs lamp
```

or, for an isolated project:

```bash
docker compose --env-file .env.myproject1 logs lamp
```

Look for:

```text
Running /docker-entrypoint-initdb.d/...
```

If the wrong file is shown, check `DB_INIT_DIR` with:

```bash
docker compose config
```

or:

```bash
docker compose --env-file .env.myproject1 config
```

If MySQL has already initialized the volume, correcting the environment file
alone is not enough.

If the current database may be deleted, recreate only the intended deployment:

```bash
docker compose --env-file .env.myproject1 down -v
docker compose --env-file .env.myproject1 up -d
```

### `Access denied for user ...`

Example:

```text
SQLSTATE[HY000] [1045] Access denied for user 'appuser'@'localhost'
```

Check that the PHP configuration and initialization SQL agree on:

```text
database name
user
password
host = 127.0.0.1
```

Test the credentials directly inside the container:

```bash
docker compose --env-file .env.myproject1 exec lamp \
    mysql -h 127.0.0.1 -uUSERNAME -p DATABASE
```

Also check:

```bash
docker compose --env-file .env.myproject1 config
docker compose --env-file .env.myproject1 logs lamp
```

Do not use MySQL `root` as the normal database user of a PHP application.

### `Can't connect to local MySQL server through socket ...`

Example:

```text
ERROR 2002 (HY000): Can't connect to local MySQL server through socket ...
```

This commonly happens when the `mysql` client is executed on the host operating
system instead of inside the LAMP container.

Do not use:

```bash
mysql -utswuser -p tswdb
```

Use:

```bash
docker compose exec lamp \
    mysql -h 127.0.0.1 -utswuser -p tswdb
```

For an isolated project:

```bash
docker compose --env-file .env.myproject1 exec lamp \
    mysql -h 127.0.0.1 -uUSERNAME -p DATABASE
```

### HTTP port already in use

Change `WEB_PORT` in the corresponding environment file.

For example:

```ini
WEB_PORT=8080
```

Check:

```bash
docker compose --env-file .env.myproject1 config
```

Then restart:

```bash
docker compose --env-file .env.myproject1 down
docker compose --env-file .env.myproject1 up -d
```

Use:

```text
http://localhost:8080/
```

### `curl: (56) Recv failure: Connection reset by peer`

If both the application URL and `/` fail, check the complete web service before
debugging the PHP application:

```bash
docker compose --env-file .env.myproject1 ps
docker compose --env-file .env.myproject1 logs --tail=100 lamp
docker compose --env-file .env.myproject1 exec lamp apache2ctl -t
```

Then test Apache from inside the container:

```bash
docker compose --env-file .env.myproject1 exec lamp \
    curl -v http://127.0.0.1/
```

If Apache works inside the container but `localhost` fails from the host, inspect
the published port with:

```bash
docker compose --env-file .env.myproject1 config
```

---

## Logs

Apache writes its access log to standard output and its error log to standard
error, so both are available through Docker Compose.

Recent logs:

```bash
docker compose logs --tail=100 lamp
```

Follow logs continuously:

```bash
docker compose logs -f lamp
```

For an isolated project:

```bash
docker compose --env-file .env.myproject1 logs -f lamp
```

The logs also show MySQL initialization messages from the container entrypoint.

---

## Component verification

### Basic container verification

Check the service state:

```bash
docker compose ps
```

Inspect running processes:

```bash
docker compose exec lamp ps aux
```

The container should contain both `mysqld` and Apache processes.

For an isolated project:

```bash
docker compose --env-file .env.myproject1 ps
docker compose --env-file .env.myproject1 exec lamp ps aux
```

### Apache diagnostics

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

**Linux:**

```bash
docker compose exec lamp apache2ctl -M | grep -E 'rewrite|headers'
```

**Windows PowerShell:**

```powershell
docker compose exec lamp apache2ctl -M |
    Select-String -Pattern 'rewrite|headers'
```

Test Apache from inside the container:

```bash
docker compose exec lamp curl -v http://127.0.0.1/
```

### PHP diagnostics

Check version:

```bash
docker compose exec lamp php -v
```

Check the required modules.

**Linux:**

```bash
docker compose exec lamp php -m | grep -E 'PDO|pdo_mysql|mysqli|mbstring'
```

**Windows PowerShell:**

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

### MySQL diagnostics

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

### HTTP diagnostics

**Linux:**

```bash
curl -v http://localhost/
curl -v http://localhost/dbtest.php
```

**Windows PowerShell:**

```powershell
curl.exe -v http://localhost/
curl.exe -v http://localhost/dbtest.php
```

Use the configured `WEB_PORT` if it is not `80`.

---

## Installation checks

### Check the Compose version first

```bash
docker compose version
```

This project requires Docker Compose v2.

If only `docker-compose` 1.29.2 is available, install the Compose plugin using
the [official Docker instructions](https://docs.docker.com/compose/install/).

A Python traceback mentioning `compose/cli/log_printer.py`, `watch_events` or
`event['id']` comes from the unmaintained Compose v1 client, not from Apache,
PHP, MySQL or the application.

After installing Compose v2, use:

```bash
docker compose config
docker compose up -d
docker compose ps
```

### Buildx is not installed

Compose may display:

```text
WARN[0000] Docker Compose is configured to build using Bake, but buildx isn't installed
```

This concerns the image builder, not Apache, PHP, MySQL or the application.

Check:

```bash
docker buildx version
```

On Ubuntu 24.04 using Ubuntu's Docker packages:

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

Buildx includes the `docker buildx bake` command used by Compose.

See the
[official Buildx reference](https://docs.docker.com/reference/cli/docker/buildx/)
and the
[Docker Build overview](https://docs.docker.com/build/concepts/overview/).

---

## Advanced container inspection

For normal work, prefer Compose because it resolves the correct generated
container name.

Open a shell in the shared environment:

```bash
docker compose exec lamp bash
```

Open a shell in an isolated project:

```bash
docker compose --env-file .env.myproject1 exec lamp bash
```

If a deployment is already running and only its Compose project name is known:

```bash
docker compose -p myproject1 ps
docker compose -p myproject1 exec lamp bash
```

Do not use `-p` alone to create or recreate a deployment: it selects the project
name but does not load `.env.myproject1`. Use `--env-file .env.myproject1` for
`up`.

If direct Docker access is necessary, first discover the actual container name:

```bash
docker compose --env-file .env.myproject1 ps
```

Then, for example:

```bash
docker exec -it myproject1-lamp-1 bash
```

If the named container is stopped:

```bash
docker start myproject1-lamp-1
docker exec -it myproject1-lamp-1 bash
```

Do not replace `exec` with `run` when targeting an existing project.
`docker run` creates a new container from an image.

A temporary shell for inspecting only the image can be created with:

```bash
docker run --rm -it --entrypoint bash imartinezestevez/lamp:latest
```

It has none of the selected project's mounts or database volume.

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

1. `docker compose ... config`
2. `docker compose ... ps`
3. `docker compose ... logs --tail=100 lamp`
4. check Apache configuration;
5. check MySQL status;
6. test the database credentials inside the container;
7. test `http://127.0.0.1/` from inside the container;
8. test `http://localhost/` from the host.

This order separates configuration, container, Apache, MySQL, application and
host-networking problems.
