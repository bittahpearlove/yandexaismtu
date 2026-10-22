# Запуск симулятора внутри контейнера robomarvel-demo.
# Собирает проект и поднимает sim.launch.py с заданными режимами.
# Контейнер должен быть уже запущен скриптом run-container.ps1 в другом терминале.

param(
    [ValidateSet("mapping", "localization", "off")][string]$Slam = "mapping",
    [ValidateSet("true", "false")][string]$Nav = "false",
    [ValidateSet("true", "false")][string]$Detection = "false",
    [string]$Db = ""
)

$ErrorActionPreference = "Stop"
$Name = "robomarvel-demo"

& docker container inspect $Name *> $null
if ($LASTEXITCODE -ne 0) {
    Write-Host "ОШИБКА: контейнер $Name не создан. Сначала выполните run-container.ps1."
    exit 1
}

$running = (& docker inspect -f "{{.State.Running}}" $Name).Trim()
if ($running -ne "true") {
    Write-Host "ОШИБКА: контейнер $Name остановлен. Запустите его: run-container.ps1."
    exit 1
}

$launchArgs = @("slam:=$Slam", "nav:=$Nav", "detection:=$Detection")
if ($Db) { $launchArgs += "db:=$Db" }
$launch = $launchArgs -join " "

$cmd = "cd /src && colcon build && source /src/install/setup.bash && ros2 launch robomarvel_sim sim.launch.py $launch"
Write-Host "Выполняю: $cmd"
& docker exec -it $Name bash -lc $cmd
