# LAMP-DOCKER

A small Docker-based **LAMP (Linux / Apache / MySQL / PHP)** development environment for the practical sessions of **Web Technologies and Services (TSW)**.

Apache, PHP and MySQL run inside a single container. This deliberately keeps the environment simple and allows PHP applications to connect to MySQL through `127.0.0.1`.

This project is intended for development and teaching purposes.

It is inspired by the [lampserver](https://www.sing-group.org/dt/gitlab/dgpena/lampserver) project.

## Stack

- Ubuntu 24.04 LTS
- Apache 2
- PHP 8.3
- PDO/MySQL, MySQLi and Mbstring
- MySQL Server
- Apache modules `rewrite` and `headers`
- Persistent MySQL data through a Docker volume

The exact Apache and MySQL package versions depend on the Ubuntu 24.04 repositories available when the image is built.

## Requirements

- Docker
- Docker Compose v2
- Docker Buildx (required when Compose builds the image with Bake)

Compose v2 is the supported version and uses the `docker compose`.

### Linux

```bash
docker --version
docker compose version
docker buildx version
```

If your user cannot access Docker directly, prepend `sudo` to the Docker commands shown below.

### Windows PowerShell

Docker Desktop must be installed and running.

```powershell
docker --version
docker compose version
docker buildx version
```

If `docker compose` is unavailable, install the Compose plugin by following the
[official Docker Compose installation guide](https://docs.docker.com/compose/install/).
If `docker buildx` is unavailable, see
[Buildx is not installed](docs/TROUBLESHOOTING.md#buildx-is-not-installed).

## Quick start

The following steps start the default test application and verify both the web server and the PHP-to-MySQL connection.

### Linux

Clone the repository and enter its root directory:

```bash
git clone <REPOSITORY-URL> lamp-docker
cd lamp-docker
```

Create the local configuration:

```bash
cp .env.example .env
```

Verify that Docker Compose is reading the expected configuration:

```bash
docker compose config
```

Build and start the environment:

```bash
docker compose up -d --build
```

The first command builds the shared `lamp-docker:latest` image. Project-specific
deployments reuse it and do not need `--build`.

Check its status:

```bash
docker compose ps
```

Test the web server:

```bash
curl --fail http://localhost/
```

Then test the PHP-to-MySQL connection:

```bash
curl --fail http://localhost/dbtest.php
```

The expected result is:

```text
PHP -> MySQL OK
```

You can also open the following URLs in a browser:

```text
http://localhost/
http://localhost/dbtest.php
```

### Windows PowerShell

Clone the repository and enter its root directory:

```powershell
git clone <REPOSITORY-URL> lamp-docker
Set-Location lamp-docker
```

Create the local configuration:

```powershell
Copy-Item .env.example .env
```

Verify that Docker Compose is reading the expected configuration:

```powershell
docker compose config
```

Build and start the environment:

```powershell
docker compose up -d --build
```

Check its status:

```powershell
docker compose ps
```

Test the web server:

```powershell
curl.exe --fail http://localhost/
```

Then test the PHP-to-MySQL connection:

```powershell
curl.exe --fail http://localhost/dbtest.php
```

The expected result is:

```text
PHP -> MySQL OK
```

You can also open the following URLs in a browser:

```text
http://localhost/
http://localhost/dbtest.php
```

## Important: run Docker Compose from the project root

The `.env` file must be located next to `compose.yaml`:

```text
lamp-docker/
├── .env
├── .env.example
├── compose.yaml
├── Dockerfile
├── db/                 # Local SQL projects are ignored by Git
├── docker/
└── www/                # Local applications are ignored by Git
```

Run `docker compose` from this directory.

Running from the project root ensures that Compose finds `compose.yaml` and
loads the expected `.env` file.

Use:

```bash
docker compose config
```

before starting the environment whenever you change `.env`.

## Default configuration

The default `.env` configuration is:

```ini
COMPOSE_PROJECT_NAME=lamp
LAMP_IMAGE=lamp-docker:latest
WEB_PORT=80
APP_DIR=./www
DB_INIT_DIR=./db/init
```

The included test database uses:

```text
host:      127.0.0.1
database:  tswdb
user:      tswuser
password:  tswpass
```

MySQL port `3306` is not exposed to the host.

## Stop the environment

Preserve the MySQL data:

```bash
docker compose down
```

To start it again:

```bash
docker compose up -d
```

Do **not** use `docker compose down -v` unless you intentionally want to delete the database volume.

## Further documentation

- [Adding and configuring projects](docs/PROJECTS.md)
- [Database initialization and management](docs/DATABASE.md)
- [Logs, verification and troubleshooting](docs/TROUBLESHOOTING.md)
- [Removing containers and images](docs/CLEANUP.md)

## License and attribution

Released under the [MIT License](LICENSE).

Copyright (c) 2026 Iván Martínez Estévez. Copies or substantial portions must retain the copyright and MIT permission notices. The software is provided without warranty.

This project is inspired by the educational [lampserver](https://www.sing-group.org/dt/gitlab/dgpena/lampserver) project.

Any reused third-party code or configuration must retain the attribution and licensing terms required by its original license or by the permission granted by its author.
