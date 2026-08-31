# Removing containers and images

This guide distinguishes between removing one LAMP-DOCKER deployment and
removing Docker resources from the entire computer.

## Inspect Docker resources first

```bash
# Running containers
docker ps

# All containers, including stopped ones
docker ps -a

# Images
docker images

# Docker disk usage
docker system df
```

## Stop or remove one container manually

Find its name or ID and then use the short commands:

```bash
docker ps -a
docker stop <container-name-or-id>
docker rm <container-name-or-id>
```

Normally, prefer `docker compose down` for LAMP-DOCKER deployments because it
also removes the corresponding Compose network cleanly.

## Remove the base `lamp` deployment

Run this from the LAMP-DOCKER root. It removes the container and network but
preserves the MySQL volume:

```bash
docker compose down
```

To also delete the base deployment's MySQL volume:

```bash
docker compose down -v
```

> **Warning:** `-v` permanently deletes every database stored by this
> deployment.

## Remove one optional project deployment

Use the same environment file that was used to start it:

```bash
docker compose --env-file .env.myproject1 down
```

To also delete only that project's MySQL volume:

```bash
docker compose --env-file .env.myproject1 down -v
```

Alternatively, identify the Compose project explicitly:

```bash
docker compose -p myproject1 down
```

## Remove the LAMP-DOCKER image

First stop every deployment that uses the shared image. Then remove it:

```bash
docker rmi lamp-docker:latest
```

If Docker reports that the image is in use, inspect the associated containers
instead of immediately forcing its removal:

```bash
docker ps -a --filter ancestor=lamp-docker:latest
```

The image can be created again with:

```bash
docker compose up -d --build
```

## Remove all stopped containers on the computer

The recommended global cleanup removes stopped containers only and asks for
confirmation:

```bash
docker container prune
```

Running containers are not affected.

## Remove all containers on the computer

> **Danger:** this forcibly stops and removes every Docker container on the
> computer, including containers unrelated to LAMP-DOCKER.

### Linux

Inspect the list first:

```bash
docker ps -a
```

Then, only if every listed container may be deleted:

```bash
docker rm -f $(docker ps -aq)
```

### Windows PowerShell

```powershell
docker ps -a
docker ps -aq | ForEach-Object { docker rm -f $_ }
```

## Remove all unused images on the computer

This removes every image that is not referenced by a container and asks for
confirmation:

```bash
docker image prune -a
```

Images used by existing containers are preserved.

## Remove every image on the computer

> **Danger:** this affects every Docker project. Remove the containers first,
> inspect `docker images`, and continue only if every image may be deleted.

### Linux

```bash
docker images
docker rmi -f $(docker images -aq)
```

### Windows PowerShell

```powershell
docker images
docker images -aq | ForEach-Object { docker rmi -f $_ }
```

## General Docker cleanup

Docker also provides `docker system prune` for removing stopped containers,
unused networks, dangling images and build cache. Adding `-a` removes all
unused images as well. Volumes are not removed unless `--volumes` is supplied.

Read the confirmation carefully before continuing:

```bash
docker system prune
```

Official Docker documentation: https://docs.docker.com/
