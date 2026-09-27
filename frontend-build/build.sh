#!/bin/sh

# Stop if a command fails or an undefined variable is used.
set -eu

# Compose mounts the selected project at /app.
cd /app

# Install the exact versions from package-lock.json from scratch.
# If installation fails, the build will not run.
npm ci

# Run the build script defined in the project's package.json.
# Generated files remain in the project directory on the host.
exec npm run build
