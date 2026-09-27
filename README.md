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

Docker Buildx is optional and is needed only to rebuild the image locally.

Compose v2 is the supported version and uses the `docker compose` command.

### Linux

```bash
docker --version
docker compose version
```

If your user cannot access Docker directly, prepend `sudo` to the Docker commands shown below.

### Windows PowerShell

Docker Desktop must be installed and running.

```powershell
docker --version
docker compose version
```

If `docker compose` is unavailable, install the Compose plugin by following the
[official Docker Compose installation guide](https://docs.docker.com/compose/install/).

## Quick start

These steps start the included test application and verify the complete path:

```text
browser or curl -> Apache -> PHP -> MySQL
```

### Linux

Clone the repository and enter its root directory:

```bash
git clone https://github.com/imestevez/lamp-docker.git lamp-docker
cd lamp-docker
```

Create the local configuration:

```bash
cp .env.example .env
```

Verify the resolved Compose configuration:

```bash
docker compose config
```

Start the environment and keep its logs in the terminal. Docker downloads the
image automatically if necessary:

```bash
docker compose up
```

Keep this terminal open to see the Apache, PHP and MySQL logs. Run the
verification commands from a second terminal.

> **Alternative:** To run in the background, add `-d`: `docker compose up -d`.
> You can then run the verification commands in the same terminal.

If you modify `Dockerfile` or files under `docker/`, rebuild the image
explicitly with either form: `docker compose up --build` or
`docker compose up -d --build`.

Compose uses the published
[`imartinezestevez/lamp`](https://hub.docker.com/repository/docker/imartinezestevez/lamp)
image. Project-specific deployments reuse the same image.

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

Expected result:

```text
PHP -> MySQL OK
```

You can also open:

```text
http://localhost/
http://localhost/dbtest.php
```

in a browser.

### Windows PowerShell

Clone the repository and enter its root directory:

```powershell
git clone https://github.com/imestevez/lamp-docker.git lamp-docker
Set-Location lamp-docker
```

Create the local configuration:

```powershell
Copy-Item .env.example .env
```

Verify the resolved Compose configuration:

```powershell
docker compose config
```

Start the environment and keep its logs in the terminal. Docker downloads the
image automatically if necessary:

```powershell
docker compose up
```

Keep this terminal open to see the Apache, PHP and MySQL logs. Run the
verification commands from a second terminal.

> **Alternative:** To run in the background, add `-d`: `docker compose up -d`.
> You can then run the verification commands in the same terminal.

If you modify `Dockerfile` or files under `docker/`, rebuild the image
explicitly with either form: `docker compose up --build` or
`docker compose up -d --build`.

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

Expected result:

```text
PHP -> MySQL OK
```

You can also open:

```text
http://localhost/
http://localhost/dbtest.php
```

in a browser.

## Important: run Docker Compose from the project root

Keep `.env` next to `compose.yaml`:

```text
lamp-docker/
├── .env.example
├── compose.yaml
├── Dockerfile
├── db/                 # Local SQL projects are ignored by Git
├── docker/
└── www/                # Local applications are ignored by Git
```

Run `docker compose` from this directory so that Compose finds `compose.yaml`
and loads the expected `.env` file.
Note that the`.env` file is not included, you should create it from scratch of from  `.env.example`

```bash
cp .env.example .env
```

Whenever `.env` changes, check the resolved configuration before restarting:

```bash
docker compose config
```

## Default configuration

The default `.env` configuration is:

```ini
COMPOSE_PROJECT_NAME=lamp
LAMP_IMAGE=imartinezestevez/lamp:latest
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

## Add a course project

After the Quick Start, continue with
[Adding and deploying projects](docs/PROJECTS.md#adding-and-deploying-projects).

As a simple course rule:

| Project | Recommended workflow |
| --- | --- |
| Introductory or small exercise that does not need database isolation | **Shared base environment** |
| MVC, REST, database-backed project, or project that must run independently | **Isolated project deployment** |

The project guide explains both workflows step by step, including what happens
when a database volume already exists.

## Daily commands

For the shared base environment:

```bash
docker compose up -d
docker compose ps
docker compose logs --tail=100 lamp
docker compose down
```

`docker compose down` preserves MySQL data.

For isolated projects, use the corresponding `.env.<project>` file as explained
in [PROJECTS.md](docs/PROJECTS.md#option-b-create-an-isolated-project-deployment).

> Do not add `-v` to `down` unless you intentionally want to delete the selected
> deployment's MySQL volume.

## Further documentation

- [Adding and configuring projects](docs/PROJECTS.md#adding-and-deploying-projects)
- [Database initialization and management](docs/DATABASE.md#database-initialization-and-management)
- [Logs, verification and troubleshooting](docs/TROUBLESHOOTING.md#logs-verification-and-troubleshooting)
- [Removing containers and images](docs/CLEANUP.md#removing-containers-and-images)

## License and attribution

Released under the [MIT License](LICENSE).

Copyright (c) 2026 Iván Martínez Estévez. Copies or substantial portions must retain the copyright and MIT permission notices. The software is provided without warranty.

This project is inspired by the educational [lampserver](https://www.sing-group.org/dt/gitlab/dgpena/lampserver) project.

Any reused third-party code or configuration must retain the attribution and licensing terms required by its original license or by the permission granted by its author.
