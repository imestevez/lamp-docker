# Removing containers and images

This guide distinguishes between cleaning one LAMP-DOCKER deployment and
removing Docker resources from the entire computer.

Official Docker documentation: https://docs.docker.com/

## Normal LAMP-DOCKER cleanup

### Inspect the current resources

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

### Remove the base `lamp` deployment

Run this from the LAMP-DOCKER root.

Remove the container and network but preserve its MySQL volume:

```bash
docker compose down
```

To also delete the base deployment's MySQL volume:

```bash
docker compose down -v
```

> **Warning:** `-v` permanently deletes every database stored by this
> deployment.

### Remove one isolated project deployment

Use the same environment file that was used to start it:

```bash
docker compose --env-file .env.myproject1 down
```

To also delete only that project's MySQL volume:

```bash
docker compose --env-file .env.myproject1 down -v
```

Alternatively, if only the Compose project name is known:

```bash
docker compose -p myproject1 down
```

### Remove the LAMP-DOCKER image

First stop every deployment that uses the shared image.

Then remove it:

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

---

## For normal LAMP-DOCKER use, stop here

The remaining commands affect Docker resources outside the current deployment
and may affect unrelated projects.

Use them only when you understand their scope.

---

## Manual container removal

Normally prefer `docker compose down`, because it also removes the corresponding
Compose network cleanly.

If manual removal is necessary, find the container first:

```bash
docker ps -a
```

Then:

```bash
docker stop <container-name-or-id>
docker rm <container-name-or-id>
```

## Remove all stopped containers on the computer

```bash
docker container prune
```

This asks for confirmation. Running containers are not affected.

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

```bash
docker image prune -a
```

This asks for confirmation and removes images that are not referenced by a
container.

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
unused networks, dangling images and build cache.

Adding `-a` removes all unused images as well. Volumes are not removed unless
`--volumes` is supplied.

Read the confirmation carefully before continuing:

```bash
docker system prune
```

## Recommended rule

Use the least destructive command that solves the problem:

```text
stop one LAMP-DOCKER deployment
        -> docker compose ... down

recreate one deployment's database
        -> docker compose ... down -v

remove globally unused Docker resources
        -> prune commands

remove everything from Docker on the computer
        -> global remove commands (rarely needed)
```
