# Запуск ученического контейнера Robomarvel.
# Загружает образ, если его еще нет, и запускает контейнер robomarvel-sim.
# Папка со скриптом подключается внутрь контейнера как /src.

$ErrorActionPreference = "Stop"

$Name = "robomarvel-sim"
$Image = "robomarvel-sim:latest"
$Source = $PSScriptRoot

# Проверка, что Docker отвечает.
& docker info *> $null
if ($LASTEXITCODE -ne 0) {
    Write-Host "ОШИБКА: Docker не запущен. Откройте Docker Desktop и дождитесь зеленого статуса."
    exit 1
}

# Имя файла образа по архитектуре машины.
$arch = (& docker version --format "{{.Server.Arch}}").Trim()
if ($arch -eq "arm64") { $tarName = "robomarvel-sim-arm64.tar.gz" } else { $tarName = "robomarvel-sim-amd64.tar" }

# Загрузка образа, если его нет.
& docker image inspect $Image *> $null
if ($LASTEXITCODE -ne 0) {
    $tarPath = @(
        (Join-Path $Source $tarName),
        (Join-Path (Split-Path $Source -Parent) $tarName)
    ) | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
    if (-not $tarPath) {
        Write-Host "ОШИБКА: не найден файл образа $tarName. Положите его в папку комплекта."
        exit 1
    }
    Write-Host "Загружаю образ из $tarPath ..."
    & docker load -i $tarPath
}

# Контейнер уже создан: запускаем его. Иначе создаем.
& docker container inspect $Name *> $null
if ($LASTEXITCODE -eq 0) {
    Write-Host "Контейнер $Name уже создан, запускаю его."
    & docker start -ai $Name
} else {
    Write-Host "Создаю и запускаю контейнер $Name."
    & docker run -it --name $Name -v "${Source}:/src" `
        -p 127.0.0.1:8765:8765 -p 127.0.0.1:8000:8000 `
        -p 127.0.0.1:8554:8554 -p 127.0.0.1:8889:8889 -p 127.0.0.1:8189:8189/udp `
        $Image
}
