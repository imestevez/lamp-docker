# Adding and deploying projects

This guide explains how to keep several applications in one LAMP-DOCKER clone.
The normal first-contact workflow uses only the base `.env` deployment named
`lamp`. Additional `.env.<project>` files are an optional advanced mechanism
for running several isolated deployments without rebuilding the image.

## Directory layout

Clone LAMP-DOCKER only once. Store each application and its initialization SQL
inside that clone:

```text
lamp-docker/
├── .env
├── .env.myproject1 # Optional: additional deployment
├── .env.myproject2 # Optional: additional deployment
├── db/
│   ├── init/
│   ├── myproject1/
│   │   └── 01-init.sql
│   └── myproject2/
│       └── 01-init.sql
└── www/
    ├── myproject1/
    │   └── index.php
    └── myproject2/
        └── index.php
```

All commands in this guide must be run from `lamp-docker/`.

## Build the shared image once

The default environment uses the image name `lamp-docker:latest`. Build it once:

```bash
cp .env.example .env
docker compose up -d --build
```

After this first build, project deployments use the same image. Changes to
`APP_DIR`, `DB_INIT_DIR`, `WEB_PORT` or `COMPOSE_PROJECT_NAME` only recreate the
container configuration; they do not rebuild the image.

Rebuild only after changing `Dockerfile`, `docker/entrypoint.sh`, or the Apache
or PHP configuration under `docker/`.

## Default deployment with `.env`

When no alternative file is specified, Compose automatically loads `.env`.
This is the recommended workflow for the initial setup and normal classroom
exercises. No project-specific environment file is required.

The default configuration is:

```ini
COMPOSE_PROJECT_NAME=lamp
LAMP_IMAGE=lamp-docker:latest
WEB_PORT=80
APP_DIR=./www
DB_INIT_DIR=./db/init
```

Start and manage it normally:

```bash
docker compose up -d
docker compose ps
docker compose logs lamp
docker compose down
```

Because the base deployment mounts all of `./www`, applications stored there
are available as URL paths without any extra configuration. For example:

```text
www/myproject1/index.php  ->  http://localhost/myproject1/
www/myproject2/index.php  ->  http://localhost/myproject2/
```

This single `lamp` deployment is sufficient for the introductory workflow.

The Compose project name is `lamp`. Compose uses it to generate names for the
container, network and MySQL volume. With Compose v2, the container name is
normally similar to `lamp-lamp-1`.

Do not add `container_name` to `compose.yaml`: the Compose project name already
provides isolation and avoids naming collisions.

## Optional: run independent project deployments

Use this alternative only when several applications must have independent
containers and databases, or must run at the same time. Each deployment needs:

- a unique `COMPOSE_PROJECT_NAME`, to isolate its container, network and volume;
- a unique `WEB_PORT` if it will run simultaneously with another deployment;
- the corresponding application and SQL directories.

The base `.env` deployment remains available as `lamp` and does not need to be
replaced.

### Create an optional project environment file

For example, create `.env.myproject1`:

```ini
COMPOSE_PROJECT_NAME=myproject1
LAMP_IMAGE=lamp-docker:latest
WEB_PORT=8081
APP_DIR=./www/myproject1
DB_INIT_DIR=./db/myproject1
```

The values have these effects:

| Variable | Effect |
| --- | --- |
| `COMPOSE_PROJECT_NAME` | Gives this deployment its own container, network and MySQL volume |
| `LAMP_IMAGE` | Reuses the previously built LAMP image |
| `WEB_PORT` | Avoids a port conflict with other running projects |
| `APP_DIR` | Mounts this application as Apache's document root |
| `DB_INIT_DIR` | Selects its first-run SQL files |

The file is mounted as the document root, so:

```text
www/myproject1/index.php
```

is available at:

```text
http://localhost:8081/
```

### Deploy using an environment file

Inspect the resolved configuration before starting:

```bash
docker compose --env-file .env.myproject1 config
```

Start the project without rebuilding:

```bash
docker compose --env-file .env.myproject1 up -d
```

Use the same environment file for every later operation so that Compose
selects the correct project and volume:

```bash
docker compose --env-file .env.myproject1 ps
docker compose --env-file .env.myproject1 logs lamp
docker compose --env-file .env.myproject1 exec lamp bash
docker compose --env-file .env.myproject1 down
```

Do not add `--build` when only deploying or switching applications.

### Override the configuration from the console

For an occasional deployment, variables can be provided by the shell instead
of creating a file. 

> **Note:** the variables specified in the console take precedence over those defined in `.env`. Compose continues to read `.env`, but in this case, it replaces the variables with the values from the console.

### Linux

```bash
COMPOSE_PROJECT_NAME=myproject1 \
LAMP_IMAGE=lamp-docker:latest \
WEB_PORT=8081 \
APP_DIR=./www/myproject1 \
DB_INIT_DIR=./db/myproject1 \
docker compose up -d
```

This form applies the variables to that command only. Later commands must at
least identify the same Compose project:

```bash
docker compose -p myproject1 ps
docker compose -p myproject1 logs lamp
docker compose -p myproject1 down
```

Using an `.env.myproject1` file is less error-prone for regular classroom use.

### Windows PowerShell

```powershell
$env:COMPOSE_PROJECT_NAME = "myproject1"
$env:LAMP_IMAGE = "lamp-docker:latest"
$env:WEB_PORT = "8081"
$env:APP_DIR = "./www/myproject1"
$env:DB_INIT_DIR = "./db/myproject1"
docker compose up -d
```

These variables remain in the current PowerShell session. They can be removed
afterwards with:

```powershell
Remove-Item Env:COMPOSE_PROJECT_NAME
Remove-Item Env:LAMP_IMAGE
Remove-Item Env:WEB_PORT
Remove-Item Env:APP_DIR
Remove-Item Env:DB_INIT_DIR
```

### Run several applications simultaneously

Give every environment file a unique `COMPOSE_PROJECT_NAME` and `WEB_PORT`:

| File | Project name | Port | Application |
| --- | --- | --- | --- |
| `.env` | `lamp` | `80` | `./www` |
| `.env.myproject1` | `myproject1` | `8081` | `./www/myproject1` |
| `.env.myproject2` | `myproject2` | `8082` | `./www/myproject2` |
| `.env.myproject3` | `myproject3` | `8083` | `./www/myproject3` |

Start each one with its file:

```bash
docker compose --env-file .env.myproject1 up -d
docker compose --env-file .env.myproject2 up -d
docker compose --env-file .env.myproject3 up -d
```

They share `lamp-docker:latest`, but each has an independent container, network
and MySQL volume. Resetting one project's volume does not affect the others.

## Database initialization

For example, place the first-run SQL for `myproject1` in:

```text
db/myproject1/01-init.sql
```

Initialization runs only when that Compose project's MySQL volume is created.
Changing `DB_INIT_DIR` does not modify an existing volume.

To reset only `myproject1`, after confirming that its data may be discarded:

```bash
docker compose --env-file .env.myproject1 config
docker compose --env-file .env.myproject1 down -v
docker compose --env-file .env.myproject1 up -d
```

> **Warning:** `down -v` permanently deletes the databases belonging to the
> selected Compose project.

See [Database initialization and management](DATABASE.md) for SQL and database
access details.

## Optional multi-deployment checklist

This checklist is needed only for the optional multiple-deployment workflow:

1. Put the application in `www/<project>/`.
2. Put first-run SQL in `db/<project>/`.
3. Create `.env.<project>` with a unique project name and host port.
4. Keep `LAMP_IMAGE=lamp-docker:latest` to reuse the shared image.
5. Run `docker compose --env-file .env.<project> config`.
6. Confirm `APP_DIR`, `DB_INIT_DIR`, `WEB_PORT` and the project name.
7. Run `docker compose --env-file .env.<project> up -d` without `--build`.
8. Check `ps`, logs, the database connection and the application URL.
