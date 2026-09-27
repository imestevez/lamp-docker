# Frontend frameworks: build and deployment

Use this guide for React, Vue or Angular applications that compile to HTML,
JavaScript and CSS. Node compiles the frontend in a temporary Docker container;
Apache serves the generated files and PHP provides the REST API.

```text
Frontend source -> Node: npm ci + npm run build -> HTML / JS / CSS
                                                        |
                                                     Apache
                                                        |
                                                  PHP REST API
                                                        |
                                                      MySQL
```

LAMP does not need Node installed. Applications requiring a running Node SSR
server need a separate deployment; this guide covers browser applications.

## 1. Prepare the source project

You need Docker, Docker Compose v2 and an existing npm frontend project with:

- `package.json`, including a `build` script;
- `package-lock.json`, consistent with `package.json`;
- source files and the framework's build configuration.

The compiler does not create a React/Vue/Angular project or convert an existing
frontend. Internet access is needed to download the Node image and dependencies.

| Project | Typical build script | Typical generated directory |
| --- | --- | --- |
| React with Vite | `vite build` | `dist/` |
| Vue with Vite | `vite build` | `dist/` |
| Angular CLI | `ng build` | `dist/<application>/browser/` |

Check your project's configuration: custom projects and older Angular builders
may use another output directory. Select the browser files, not a server bundle.
The Node image is configured in `frontend-build/compose.yaml`; use a version
compatible with the project's dependencies.

## 2. Configure the compiler

Start at the `lamp-docker/` repository root. Create the configuration once;
if `frontend-build/.env` already exists, edit it instead of overwriting it.

**Linux:**

```bash
cp frontend-build/.env.example frontend-build/.env
id -u
id -g
```

Add the returned numeric IDs as `BUILD_UID` and `BUILD_GID` in
`frontend-build/.env` so generated files belong to your user. For example:

```ini
BUILD_UID=1000
BUILD_GID=1000
```

**Windows PowerShell:**

```powershell
Copy-Item frontend-build/.env.example frontend-build/.env
```

Use Docker Desktop with Linux containers; the default UID/GID can remain.

**Both systems:** set the source directory in `frontend-build/.env`:

```ini
FRONTEND_SOURCE=../www/mvcblog/frontend
```

Paths are relative to `frontend-build/`, not the repository root. For an
external project, use a suitable relative path such as `../../my-frontend`
or an absolute path (`C:/projects/my-frontend` also works on Windows).
The selected directory must exist and contain `package.json`.

These files have different responsibilities:

| File | Purpose |
| --- | --- |
| `frontend-build/.env` | Select source code and build user |
| `.env` or `.env.<project>` at the repository root | Configure LAMP, its application mount, port and database initialization |

## 3. Set the public paths

Decide where Apache will publish the frontend before compiling:

| LAMP configuration | Frontend directory on the host | Frontend URL path | API URL path |
| --- | --- | --- | --- |
| `APP_DIR=./www` | `www/mvcblog/frontend/` | `/mvcblog/frontend/` | `/mvcblog/rest/` |
| `APP_DIR=./www/mvcblog` | `www/mvcblog/frontend/` | `/frontend/` | `/rest/` |

For React/Vue with Vite, set `base` in `vite.config.js` to the public frontend
path, for example `base: '/frontend/'`. For Angular, set `baseHref` in the
application's build options in `angular.json`, for example `/frontend/`.
Configure the frontend router's base too if required by its router.

The local MVCBlog React example uses `base: './'` and hash navigation, so its
assets work in either location. Its API path is `../rest`: the frontend and
REST directories are siblings. Avoid hardcoding `/mvcblog/rest` when publishing
the application directly at the server root.

For path-based frontend navigation without `#`, put this `.htaccess` inside
the published frontend directory, or include it in the project's public assets:

```apache
DirectoryIndex index.html
RewriteEngine On
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule ^ index.html [L]
```

Keep the API outside that directory. The API has its own rewrite rules; the
frontend fallback must not intercept API requests. LAMP already supports
`rewrite` and `.htaccess`.

## 4. Compile

From the repository root, these commands work in Linux and PowerShell:

```bash
cd frontend-build
docker compose config
docker compose run --rm builder
cd ..
```

The builder runs `npm ci && npm run build` on the mounted source directory.
`npm ci` recreates `node_modules` from the lockfile. Use the Docker build
workflow consistently rather than sharing those dependencies with host Node
tools. A failed install stops the build.

The container is removed afterwards, while generated files stay on your host.
This command compiles the frontend; it does not start or rebuild LAMP.

## 5. Publish and start LAMP

For a typical project, copy the **contents** of its output directory into the
dedicated frontend directory served by Apache. For example, copy the contents
of `dist/` into `www/my-app/frontend/`. Publish the browser output, not source
JSX or `node_modules`. Keep backend PHP and uploaded files separate when
replacing a previous generated frontend.

**Local MVCBlog React example:** its custom Vite configuration reads
`frontend/src/index.html` and writes `frontend/index.html` and `frontend/assets/`
directly. No copy is needed. Edit `src/`, not the generated `index.html`.
`emptyOutDir: false` preserves the source files alongside this custom output.

From the repository root, start the deployment you configured.

**Shared environment (`APP_DIR=./www` in `.env`):**

```bash
docker compose up -d
```

Open `http://localhost/mvcblog/frontend/` for MVCBlog.

**Isolated MVCBlog (`APP_DIR=./www/mvcblog` in `.env.mvcblog`):**

```bash
docker compose --env-file .env.mvcblog up -d
```

Open `http://localhost/frontend/`.

Add the configured `WEB_PORT` to the URL if it is not 80. Use the same LAMP
environment file for subsequent operations. The application's database must
already be prepared; see [database management](DATABASE.md). Recompiling a
frontend does not require importing SQL or resetting the database.

## 6. Verify and repeat after changes

Open the frontend and check the browser's Network panel:

- the HTML, JavaScript and CSS load successfully;
- API requests use the expected path and return JSON;
- login, listing, editing and comments work with the PHP backend.

For the isolated MVCBlog deployment, verify its read-only API directly:

**Linux:**

```bash
curl --fail http://localhost/rest/post
```

**Windows PowerShell:**

```powershell
curl.exe --fail http://localhost/rest/post
```

For the shared deployment, use `/mvcblog/rest/post` instead.

After changing source files, repeat the build command in step 4 and copy the
output again if your project requires it. Reload the browser with Ctrl+F5.
Mounted static-file changes do not require rebuilding the LAMP image or
restarting the container.

## Common problems

| Symptom | Check |
| --- | --- |
| `package.json` not found | `FRONTEND_SOURCE` and its path relative to `frontend-build/` |
| `npm ci` fails | Lockfile consistency, network access and compatible Node version |
| Files cannot be written | Linux `BUILD_UID`/`BUILD_GID` and host directory ownership |
| Blank page or JS/CSS 404 | Open compiled output and check the public base path |
| Frontend loads but API returns 404/HTML | API URL, `APP_DIR` and REST `.htaccess`; a hardcoded `RewriteBase /mvcblog/rest` is wrong when serving at `/rest` |
| Works through links but refresh returns 404 | Frontend router base and Apache fallback, or use hash navigation |
| Changes are not visible | Recompile, publish the new output and refresh the browser |

References: [Vite build paths](https://vite.dev/guide/build#public-base-path),
[Angular deployment](https://angular.dev/tools/cli/deployment) and
[Angular/Node compatibility](https://angular.dev/reference/versions).
