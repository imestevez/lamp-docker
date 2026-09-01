# Adding and deploying projects

LAMP-DOCKER supports two ways of organizing course projects.

You do not need to understand both workflows before starting. Use this rule
unless the exercise instructions say otherwise:

```text
Small exercise without database isolation
                |
                v
     Shared base environment


MVC / REST / own database / independent project
                |
                v
     Isolated project deployment
```

## First choose a workflow

| | Shared base environment | Isolated project deployment |
| --- | --- | --- |
| Best for | Introductory exercises and several small applications | Projects that need independent data or must run simultaneously |
| PHP location | `www/<project>/` | Configurable with `APP_DIR` |
| URL | `http://localhost/<project>/` | `http://localhost:<port>/` |
| Environment file | Existing `.env` | New `.env.<project>` |
| Database volume | Shared by every application | Exclusive to the project |
| SQL location | `db/init/` or manual import | Configurable with `DB_INIT_DIR` |
| Commands | `docker compose ...` | `docker compose --env-file .env.<project> ...` |

Use the shared environment when database isolation is unnecessary. Use an
isolated deployment when resetting or changing one project's database must not
affect the others.

All commands below must be run from the `lamp-docker/` directory. Local
applications, project SQL and `.env.<project>` files are intentionally ignored
by this repository. Put work that must be submitted or shared in its own
repository.

## One-time installation check

Do this once after installing or cloning LAMP-DOCKER.

### Linux

```bash
cp .env.example .env
docker compose up -d
curl --fail http://localhost/dbtest.php
```

### Windows PowerShell

```powershell
Copy-Item .env.example .env
docker compose up -d
curl.exe --fail http://localhost/dbtest.php
```

Expected response:

```text
PHP -> MySQL OK
```

This verifies Apache, PHP and MySQL using the published
`imartinezestevez/lamp:latest` image.

Only maintainers changing the `Dockerfile` or files under `docker/` need to
rebuild locally. PHP, HTML, CSS, JavaScript and SQL changes never require it.

---

## Option A: use the shared base environment

This option keeps one container and one MySQL volume for all applications. It
uses the existing `.env`:

```ini
COMPOSE_PROJECT_NAME=lamp
LAMP_IMAGE=imartinezestevez/lamp:latest
WEB_PORT=80
APP_DIR=./www
DB_INIT_DIR=./db/init
```

### Add an application without its own database

Create the application under `www/`:

```text
www/myproject1/
└── index.php
```

It is available at:

```text
http://localhost/myproject1/
```

Start or reuse the base environment:

```bash
docker compose up -d
```

Because `www/` is mounted from the host, application changes are visible
immediately.

### Add a database to the shared environment

The key point is:

> `db/init/` is automatic only when the shared MySQL volume is created for the
> first time.

There are therefore two cases.

**Before the first start:** place the SQL file in `db/init/`. Every `*.sql`
file there is executed once, in alphabetical order.

**After the environment has already been started:** import the SQL manually.
Adding a new file to `db/init/` alone will not execute it.

If you completed the one-time installation check above, the shared volume
already exists, so manual import is normally the case.

Create, for example:

```text
db/myproject1/
└── 01-init.sql
```

Then import it.

Linux:

```bash
docker compose exec -T lamp mysql -uroot < db/myproject1/01-init.sql
```

Windows PowerShell:

```powershell
Get-Content .\db\myproject1\01-init.sql -Raw |
    docker compose exec -T lamp mysql -uroot
```

This adds the new database to the existing shared MySQL volume without deleting
the databases of other exercises.

The PHP application connects to:

```text
host: 127.0.0.1
port: 3306
```

using the database name, user and password created by its SQL.

Useful commands for the shared environment:

```bash
docker compose ps
docker compose logs lamp
docker compose down
```

`docker compose down` preserves the shared database volume.

> Avoid `docker compose down -v` in the shared environment unless you really
> want to delete **all databases stored in that shared volume**.

---

## Option B: create an isolated project deployment

Use this option when the project should have its own container, port and MySQL
volume while reusing `imartinezestevez/lamp:latest`.

`www/` and `db/` are convenient defaults, not required locations. Compose uses
the directories selected by `APP_DIR` and `DB_INIT_DIR`. These may point either
inside `lamp-docker` or to another location available to Docker.

Relative paths are resolved from the `lamp-docker` directory containing
`compose.yaml`, not from the location of the environment file.

Choose one of the following layouts.

### Option B.1: keep the project inside `lamp-docker`

This layout is convenient for local exercises managed together with the LAMP
environment:

```text
lamp-docker/
├── .env.myproject1
├── compose.yaml
├── www/
│   └── myproject1/
│       └── index.php
└── db/
    └── myproject1/
        └── 01-init.sql
```

Create `.env.myproject1` with:

```ini
COMPOSE_PROJECT_NAME=myproject1
LAMP_IMAGE=imartinezestevez/lamp:latest
WEB_PORT=8080
APP_DIR=./www/myproject1
DB_INIT_DIR=./db/myproject1
```

### Option B.2: keep the project outside `lamp-docker`

Use this layout when the application has its own repository. For example, the
repositories may be siblings:

```text
workspace/
├── lamp-docker/
│   ├── .env.myproject1
│   └── compose.yaml
└── myproject1/
    ├── database.sql
    └── index.php
```

The environment file can point to that sibling repository:

```ini
COMPOSE_PROJECT_NAME=myproject1
LAMP_IMAGE=imartinezestevez/lamp:latest
WEB_PORT=8080
APP_DIR=../myproject1
DB_INIT_DIR=../myproject1
```

`DB_INIT_DIR` must identify a directory, not an individual SQL file. On the
first volume initialization, LAMP-Docker executes every `*.sql` file located
directly in that directory. If the application stores SQL in a dedicated
subdirectory, point to it instead, for example:

```ini
APP_DIR=../myproject1
DB_INIT_DIR=../myproject1/database/init
```

Absolute paths are also supported, but relative paths are usually more portable
between development machines.

### Common database configuration

In either layout, an initialization file can create the database and application
user:

```sql
CREATE DATABASE myproject1
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

CREATE USER 'myproject1'@'localhost'
IDENTIFIED BY 'change-this-password';

GRANT ALL PRIVILEGES
ON myproject1.*
TO 'myproject1'@'localhost';
```

The PHP application uses the same database name, user and password and connects
to host `127.0.0.1` on port `3306`.

Each simultaneous deployment needs a unique `COMPOSE_PROJECT_NAME` and
`WEB_PORT`.

`APP_DIR` selects the Apache document root. Therefore this application is served
directly at:

```text
http://localhost:8080/
```

not at:

```text
http://localhost:8080/myproject1/
```

`DB_INIT_DIR` selects the SQL that is executed when this project's MySQL volume
is created for the first time.

### Check the configuration before starting

```bash
docker compose --env-file .env.myproject1 config
```

Check that:

- `APP_DIR` resolves to the intended application directory;
- `DB_INIT_DIR` resolves to the intended SQL directory;
- the expected host port is used;
- the expected Compose project name is used.

This check is especially important before any command that includes `-v`.

### Start and verify

```bash
docker compose --env-file .env.myproject1 up -d
docker compose --env-file .env.myproject1 ps
docker compose --env-file .env.myproject1 logs lamp
```

On the first start, the logs should contain:

```text
Running /docker-entrypoint-initdb.d/01-init.sql
```

Open:

```text
http://localhost:8080/
```

If needed, verify the database directly:

```bash
docker compose --env-file .env.myproject1 exec lamp \
    mysql -h 127.0.0.1 -umyproject1 -p myproject1
```

### Manage the project later

Always use the same environment file:

```bash
docker compose --env-file .env.myproject1 up -d
docker compose --env-file .env.myproject1 ps
docker compose --env-file .env.myproject1 logs lamp
docker compose --env-file .env.myproject1 exec lamp bash
docker compose --env-file .env.myproject1 down
```

Prefer `docker compose ... exec` over relying on a generated container name.
Compose resolves the correct container automatically.

`down` preserves this project's database.

If the initialization SQL is changed during development and the existing data
may be discarded, recreate only this project's volume:

```bash
docker compose --env-file .env.myproject1 config
docker compose --env-file .env.myproject1 down -v
docker compose --env-file .env.myproject1 up -d
```

> **Warning:** `down -v` permanently deletes the selected project's database.

---

## Run several isolated projects simultaneously

Give each environment file a different project name and host port:

| File | Project name | Port | Application | SQL |
| --- | --- | --- | --- | --- |
| `.env.myproject1` | `myproject1` | `8080` | `./www/myproject1` | `./db/myproject1` |
| `.env.myproject2` | `myproject2` | `8081` | `./www/myproject2` | `./db/myproject2` |

Start both:

```bash
docker compose --env-file .env.myproject1 up -d
docker compose --env-file .env.myproject2 up -d
```

They share the image but have independent containers, networks and database
volumes.

---

## Quick decision checklist

- Small exercise, no database isolation needed: use **Option A**.
- Several small applications may share one MySQL volume: use **Option A**.
- Existing shared volume needs another database: import its SQL manually.
- MVC/REST project with its own database: normally use **Option B**.
- Project needs its own disposable database: use **Option B**.
- Projects must run simultaneously on different ports: use **Option B**.
- Changing an initialization file after first start: import the change manually
  or recreate only the appropriate volume if its data may be deleted.

See [Database initialization and management](DATABASE.md#database-initialization-and-management)
for detailed database commands.
