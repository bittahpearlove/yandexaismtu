#!/usr/bin/env bash
# Запуск демонстрационного контейнера Robomarvel.
# Загружает образ, если его еще нет, и запускает контейнер robomarvel-demo.
# Папка со скриптом подключается внутрь контейнера как /src.
set -euo pipefail

NAME="robomarvel-demo"
IMAGE="robomarvel-sim:latest"
SOURCE="$(cd "$(dirname "$0")" && pwd)"

command -v docker >/dev/null 2>&1 || { echo "ОШИБКА: docker не найден"; exit 1; }
docker info >/dev/null 2>&1 || { echo "ОШИБКА: Docker не запущен"; exit 1; }

arch="$(docker version --format '{{.Server.Arch}}')"
if [ "$arch" = "arm64" ]; then
  tar_name="robomarvel-sim-arm64.tar.gz"
else
  tar_name="robomarvel-sim-amd64.tar"
fi

if ! docker image inspect "$IMAGE" >/dev/null 2>&1; then
  tar_path=""
  for dir in "$SOURCE" "$SOURCE/.."; do
    if [ -f "$dir/$tar_name" ]; then
      tar_path="$dir/$tar_name"
      break
    fi
  done
  if [ -z "$tar_path" ]; then
    echo "ОШИБКА: не найден файл образа $tar_name. Положите его в папку комплекта."
    exit 1
  fi
  echo "Загружаю образ из $tar_path ..."
  docker load -i "$tar_path"
fi

if docker container inspect "$NAME" >/dev/null 2>&1; then
  echo "Контейнер $NAME уже создан, запускаю его."
  exec docker start -ai "$NAME"
else
  echo "Создаю и запускаю контейнер $NAME."
  exec docker run -it --name "$NAME" -v "$SOURCE:/src" \
    -p 127.0.0.1:8765:8765 \
    -p 127.0.0.1:8000:8000 \
    -p 127.0.0.1:8554:8554 \
    -p 127.0.0.1:8889:8889 \
    -p 127.0.0.1:8189:8189/udp \
    "$IMAGE"
fi
