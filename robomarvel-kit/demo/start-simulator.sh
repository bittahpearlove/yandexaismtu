#!/usr/bin/env bash
# Запуск симулятора внутри контейнера robomarvel-demo.
# Собирает проект и поднимает sim.launch.py с заданными режимами.
# Контейнер должен быть уже запущен скриптом run-container.sh в другом терминале.
#
# Примеры:
#   ./start-simulator.sh
#   ./start-simulator.sh localization true true /src/maps/classroom_good.db
set -euo pipefail

NAME="robomarvel-demo"

slam="${1:-mapping}"
nav="${2:-false}"
detection="${3:-false}"
db="${4:-}"

if ! docker container inspect "$NAME" >/dev/null 2>&1; then
  echo "ОШИБКА: контейнер $NAME не создан. Сначала выполните run-container.sh."
  exit 1
fi

running="$(docker inspect -f '{{.State.Running}}' "$NAME")"
if [ "$running" != "true" ]; then
  echo "ОШИБКА: контейнер $NAME остановлен. Запустите его: run-container.sh."
  exit 1
fi

launch="slam:=$slam nav:=$nav detection:=$detection"
if [ -n "$db" ]; then
  launch="$launch db:=$db"
fi

cmd="cd /src && colcon build && source /src/install/setup.bash && ros2 launch robomarvel_sim sim.launch.py $launch"
echo "Выполняю: $cmd"
exec docker exec -it "$NAME" bash -lc "$cmd"
