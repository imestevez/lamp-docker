# Compile a frontend with Docker

For the complete workflow, see [Build and publish frontend frameworks](../docs/FRONTEND.md).

This folder runs [build.sh](build.sh) inside a Node container. The script runs:

```bash
npm ci
npm run build
```

The first installs the project's dependencies. The second compiles it.
You only need Docker and Docker Compose on your computer. LAMP stays unchanged.

## 1. Select your project

Use an existing React, Vue or Angular npm project with `package.json`,
`package-lock.json` and a `build` script. This does not convert Fronty to another
framework. Internet access is needed to download the image and dependencies.

From the repository root:

**Linux:**

```bash
cd frontend-build
cp .env.example .env
export BUILD_UID=$(id -u)
export BUILD_GID=$(id -g)
```

The IDs make generated files belong to your Linux user. Alternatively, save
those numeric values as `BUILD_UID` and `BUILD_GID` in `.env`.

**Windows PowerShell:**

```powershell
Set-Location frontend-build
Copy-Item .env.example .env
```

Use Docker Desktop with Linux containers.

Edit `.env` to point to your project:

```ini
FRONTEND_SOURCE=../www/mvcblog/frontend
```

The included local [React blog example](../www/mvcblog/frontend/README.md) uses
that path. For another project, replace it with its source directory.

Relative paths start at `frontend-build/`. Absolute paths also work, for
example `C:/projects/my-frontend` on Windows.

## 2. Compile

From `frontend-build/`, on either operating system:

```bash
docker compose run --rm builder
```

The container uses your project directory directly. `npm ci` recreates its
`node_modules`, then `npm run build` generates the output. Use this Docker
workflow consistently instead of sharing dependencies with host Node tools.
If the lockfile is missing or inconsistent, fix it in the source project first.

| Project | Typical build script | Typical output directory |
| --- | --- | --- |
| React with Vite | `vite build` | `dist/` |
| Vue with Vite | `vite build` | `dist/` |
| Angular CLI | `ng build` | `dist/my-app/browser/` |

The project controls the output path; check its configuration if it differs.
Each run uses the same output directory. The container is removed afterwards,
but the generated files stay in your project.

The Node version is set by `image` in `compose.yaml`. Change it if your project
requires another version; check [Angular compatibility](https://angular.dev/reference/versions)
for Angular projects.

## Included MVCBlog React example

For `FRONTEND_SOURCE=../www/mvcblog/frontend`, the Vite configuration writes
`index.html` and `assets/` directly into `www/mvcblog/frontend/`. After building,
open `http://localhost/mvcblog/frontend/` with LAMP running and the existing
MVCBlog database ready. For an isolated deployment with `APP_DIR=./www/mvcblog`, open
`http://localhost/frontend/` instead. No copy step is needed for this example. Edit files in
`src/`; the top-level `index.html` is generated.

## 3. Copy the result to LAMP (other projects)

Copy the **contents** of the output directory to the frontend directory served
by Apache, for example `www/my-app/frontend/`. Publish only browser output;
SSR that needs a Node server requires a separate deployment.

Before compiling, configure the public path to match that destination:

- React/Vue with Vite: set `base: '/my-app/frontend/'` in the Vite configuration.
- Angular: set `baseHref` to `/my-app/frontend/` in the application's build options
  in `angular.json`.

If you mount the application itself as `APP_DIR`, the frontend path is instead
`/frontend/`. Configure the frontend's API URL to point to your PHP REST API.

For frontend routes without `#`, add this `.htaccess` to the published frontend
directory (keep the PHP API outside it):

```apache
DirectoryIndex index.html
RewriteEngine On
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule ^ index.html [L]
```

Configure the frontend router's base path too if its router requires it.
See [Vite deployment paths](https://vite.dev/guide/build#public-base-path) and
[Angular deployment](https://angular.dev/tools/cli/deployment).
