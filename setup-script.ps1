# -----------------------------------------------------------------------------
# Проверка окружения
# -----------------------------------------------------------------------------

Write-Host "Проверка окружения...`n"

# Проверка запуска от администратора
$isAdmin = ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "❌ Скрипт нужно запускать от имени администратора!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Решение:" -ForegroundColor Yellow
    Write-Host "ПКМ по setup.bat → 'Запуск от имени администратора'"
    Write-Host ""

    exit
}

# Проверка наличия winget
$wingetExists = Get-Command winget -ErrorAction SilentlyContinue
if (-not $wingetExists) {
    Write-Host "❌ winget не найден или не доступен в PATH!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Попробуй:"
    Write-Host "- установить App Installer из Microsoft Store"
    Write-Host "- перезапустить PowerShell"
    Write-Host ""

    exit
}

# -----------------------------------------------------------------------------
# Настройки Проводника: показывать расширения и скрытые файлы
# -----------------------------------------------------------------------------

Write-Host "Настройка Проводника Windows..."

$explorerAdvanced = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"

# Показывать скрытые файлы и папки
Set-ItemProperty -Path $explorerAdvanced -Name Hidden -Value 1

# Показывать расширения файлов
Set-ItemProperty -Path $explorerAdvanced -Name HideFileExt -Value 0

# Перезапуск Проводника, чтобы настройки применились сразу
Stop-Process -Name explorer -ErrorAction SilentlyContinue
Start-Sleep -Milliseconds 500
Start-Process explorer.exe

Write-Host "Настройки Проводника применены.`n"

# -----------------------------------------------------------------------------
# Вспомогательные функции
# -----------------------------------------------------------------------------

# Функция проверяющая, установлено ли приложение
function Test-AppInstalled {
    param(
        [Parameter(Mandatory = $true)]
        [string] $PackageId,

        [Parameter(Mandatory = $false)]
        [string] $InstalledName
    )

    winget list --id $PackageId --exact --source winget | Out-Null

    if ($LASTEXITCODE -eq 0) {
        return $true
    }

    if (-not [string]::IsNullOrWhiteSpace($InstalledName)) {
        winget list --name $InstalledName | Out-Null

        if ($LASTEXITCODE -eq 0) {
            return $true
        }
    }

    return $false
}

# -----------------------------------------------------------------------------
# Приложение: Bitwarden
# Репозиторий: https://github.com/microsoft/winget-pkgs/tree/master/manifests/b/Bitwarden/Bitwarden
# -----------------------------------------------------------------------------

$packageId = "Bitwarden.Bitwarden"
$version = "2026.3.1"
$installedName = "Bitwarden"

if (Test-AppInstalled -PackageId $packageId -InstalledName $installedName) {
    Write-Host "$installedName уже установлен."
} else {
    Write-Host "Установка $installedName..."

    winget install `
      --id $packageId `
      --exact `
      --version $version `
      --source winget `
      --installer-type nullsoft `
      --architecture x64 `
      --scope machine `
      --accept-package-agreements `
      --accept-source-agreements `
      --silent `
      --custom "/allusers"

    if ($LASTEXITCODE -ne 0) {
        Write-Warning "Ошибка установки $installedName. Код завершения winget: $LASTEXITCODE. Пропускаем."
    } else {
        Write-Host "$installedName установлен успешно."
    }
}

# -----------------------------------------------------------------------------
# Приложение: CapCut
# Репозиторий: https://github.com/microsoft/winget-pkgs/tree/master/manifests/b/ByteDance/CapCut
# -----------------------------------------------------------------------------

$packageId = "ByteDance.CapCut"
$version = "8.5.0.3590"
$installedName = "CapCut"

if (Test-AppInstalled -PackageId $packageId -InstalledName $installedName) {
    Write-Host "$installedName уже установлен."
} else {
    Write-Host "Установка $installedName..."

    winget install `
      --id $packageId `
      --exact `
      --version $version `
      --source winget `
      --architecture x64 `
      --accept-package-agreements `
      --accept-source-agreements `
      --silent

    if ($LASTEXITCODE -ne 0) {
        Write-Warning "Ошибка установки $installedName. Код: $LASTEXITCODE. Пропускаем."
    } else {
        Write-Host "$installedName установлен успешно."
    }
}

# -----------------------------------------------------------------------------
# Приложение: Chocolatey
# Репозиторий: https://github.com/microsoft/winget-pkgs/tree/master/manifests/c/Chocolatey/Chocolatey
# -----------------------------------------------------------------------------

$packageId = "Chocolatey.Chocolatey"
$version = "2.7.1.0"
$installedName = "Chocolatey"

if (Test-AppInstalled -PackageId $packageId -InstalledName $installedName) {
    Write-Host "$installedName уже установлен."
} else {
    Write-Host "Установка $installedName..."

    winget install `
      --id $packageId `
      --exact `
      --version $version `
      --source winget `
      --installer-type wix `
      --scope machine `
      --accept-package-agreements `
      --accept-source-agreements `
      --silent

    if ($LASTEXITCODE -ne 0) {
        Write-Warning "Ошибка установки $installedName. Код: $LASTEXITCODE. Пропускаем..."
    } else {
        Write-Host "$installedName установлен успешно."
    }
}

# -----------------------------------------------------------------------------
# Приложение: Discord
# Репозиторий: https://github.com/microsoft/winget-pkgs/tree/master/manifests/d/Discord/Discord
# -----------------------------------------------------------------------------

$packageId = "Discord.Discord"
$installedName = "Discord"

if (Test-AppInstalled -PackageId $packageId -InstalledName $installedName) {
    Write-Host "$installedName уже установлен."
} else {
    Write-Host "Установка $installedName..."

    winget install `
      --id $packageId `
      --exact `
      --source winget `
      --accept-package-agreements `
      --accept-source-agreements `
      --silent

	if ($LASTEXITCODE -ne 0) {
		Write-Warning "Ошибка установки $installedName. Код завершения работы winget: $LASTEXITCODE."
	} else {
		Write-Host "$installedName установлен успешно."
	}
}

# -----------------------------------------------------------------------------
# Приложение: Epic Games Launcher
# Репозиторий: https://github.com/microsoft/winget-pkgs/tree/master/manifests/e/EpicGames/EpicGamesLauncher
# -----------------------------------------------------------------------------

$packageId = "EpicGames.EpicGamesLauncher"
$version = "1.3.161.0"
$installedName = "Epic Games Launcher"

if (Test-AppInstalled -PackageId $packageId -InstalledName $installedName) {
    Write-Host "$installedName уже установлен."
} else {
    Write-Host "Установка $installedName..."

    winget install `
      --id $packageId `
      --exact `
      --version $version `
      --source winget `
      --installer-type wix `
      --architecture x64 `
      --scope machine `
      --accept-package-agreements `
      --accept-source-agreements `
      --silent

    if ($LASTEXITCODE -ne 0) {
        Write-Warning "Ошибка установки $installedName. Код завершения winget: $LASTEXITCODE. Пропускаем."
    } else {
        Write-Host "$installedName установлен успешно."
    }
}

# -----------------------------------------------------------------------------
# Приложение: Git
# Репозиторий: https://github.com/microsoft/winget-pkgs/tree/master/manifests/g/Git/Git
# -----------------------------------------------------------------------------

$packageId = "Git.Git"
$version = "2.54.0"
$installedName = "Git"

if (Test-AppInstalled -PackageId $packageId -InstalledName $installedName) {
    Write-Host "$installedName уже установлен."
} else {
    Write-Host "Установка $installedName..."

    winget install `
      --id $packageId `
      --exact `
      --version $version `
      --source winget `
      --installer-type inno `
      --architecture x64 `
      --scope machine `
      --accept-package-agreements `
      --accept-source-agreements `
      --silent

	if ($LASTEXITCODE -ne 0) {
		Write-Warning "Ошибка установки $installedName. Код завершения работы winget: $LASTEXITCODE."
	} else {
		Write-Host "$installedName установлен успешно."
	}
}

# -----------------------------------------------------------------------------
# Приложение: Notepad++
# Репозиторий: https://github.com/microsoft/winget-pkgs/tree/master/manifests/n/Notepad%2B%2B/Notepad%2B%2B
# -----------------------------------------------------------------------------

$packageId = "Notepad++.Notepad++"
$version = "8.9.2"
$installedName = "Notepad++"

if (Test-AppInstalled -PackageId $packageId -InstalledName $installedName) {
    Write-Host "$installedName уже установлен."
} else {
    Write-Host "Установка $installedName..."

    winget install `
      --id $packageId `
      --exact `
      --version $version `
      --source winget `
      --installer-type wix `
      --architecture x64 `
      --scope machine `
      --accept-package-agreements `
      --accept-source-agreements `
      --silent

	if ($LASTEXITCODE -ne 0) { 
		Write-Warning "Ошибка установки $installedName. код завершения работы winget: $LASTEXITCODE."
	} else { 
		Write-Host "$installedName установлен успешно."
	}
}

# -----------------------------------------------------------------------------
# Приложение: Notion
# Репозиторий: https://github.com/microsoft/winget-pkgs/tree/master/manifests/n/Notion/Notion
# -----------------------------------------------------------------------------

$packageId = "Notion.Notion"
$version = "7.9.0"
$installedName = "Notion"

if (Test-AppInstalled -PackageId $packageId -InstalledName $installedName) {
    Write-Host "$installedName уже установлен."
} else {
    Write-Host "Установка $installedName..."

    winget install `
      --id $packageId `
      --exact `
      --version $version `
      --source winget `
      --installer-type nullsoft `
      --architecture x64 `
      --accept-package-agreements `
      --accept-source-agreements `
      --silent

    if ($LASTEXITCODE -ne 0) {
        Write-Warning "Ошибка установки $installedName. Код завершения winget: $LASTEXITCODE. Пропускаем."
    } else {
        Write-Host "$installedName установлен успешно."
    }
}

# -----------------------------------------------------------------------------
# Приложение: Postman
# Репозиторий: https://github.com/microsoft/winget-pkgs/tree/master/manifests/p/Postman/Postman
# -----------------------------------------------------------------------------

$packageId = "Postman.Postman"
$version = "12.7.6"
$installedName = "Postman"

if (Test-AppInstalled -PackageId $packageId -InstalledName $installedName) {
    Write-Host "$installedName уже установлен."
} else {
    Write-Host "Установка $installedName..."

    winget install `
      --id $packageId `
      --exact `
      --version $version `
      --source winget `
      --architecture x64 `
      --accept-package-agreements `
      --accept-source-agreements `
      --silent

    if ($LASTEXITCODE -ne 0) {
        Write-Warning "Ошибка установки $installedName. Код: $LASTEXITCODE. Пропускаем."
    } else {
        Write-Host "$installedName установлен успешно."
    }
}

# -----------------------------------------------------------------------------
# Приложение: qBittorrent
# Репозиторий: https://github.com/microsoft/winget-pkgs/tree/master/manifests/q/qBittorrent/qBittorrent
# -----------------------------------------------------------------------------

$packageId = "qBittorrent.qBittorrent"
$version = "5.1.4"
$installedName = "qBittorrent"

if (Test-AppInstalled -PackageId $packageId -InstalledName $installedName) {
    Write-Host "$installedName уже установлен."
} else {
    Write-Host "Установка $installedName..."

    winget install `
      --id $packageId `
      --exact `
      --version $version `
      --source winget `
      --installer-type nullsoft `
      --architecture x64 `
      --scope machine `
      --accept-package-agreements `
      --accept-source-agreements `
      --silent

	if ($LASTEXITCODE -ne 0) {
		Write-Warning "Ошибка установки $installedName. Код завершения работы winget: $LASTEXITCODE."
	} else {
		Write-Host "$installedName установлен успешно."
	}
}

# -----------------------------------------------------------------------------
# Приложение: Steam
# Репозиторий: https://github.com/microsoft/winget-pkgs/tree/master/manifests/v/Valve/Steam
# -----------------------------------------------------------------------------

$packageId = "Valve.Steam"
$version = "2.10.91.91"
$installedName = "Steam"

if (Test-AppInstalled -PackageId $packageId -InstalledName $installedName) {
    Write-Host "$installedName уже установлен."
} else {
    Write-Host "Установка $installedName..."

    winget install `
      --id $packageId `
      --exact `
      --version $version `
      --source winget `
      --installer-type nullsoft `
      --scope machine `
      --accept-package-agreements `
      --accept-source-agreements `
      --silent

    if ($LASTEXITCODE -ne 0) {
        Write-Warning "Ошибка установки $installedName. Код завершения winget: $LASTEXITCODE. Пропускаем."
    } else {
        Write-Host "$installedName установлен успешно."
    }
}

# -----------------------------------------------------------------------------
# Приложение: Telegram Desktop
# Репозиторий: https://github.com/microsoft/winget-pkgs/tree/master/manifests/t/Telegram/TelegramDesktop
# -----------------------------------------------------------------------------

$packageId = "Telegram.TelegramDesktop"
$version = "6.7.8"
$installedName = "Telegram Desktop"

if (Test-AppInstalled -PackageId $packageId -InstalledName $installedName) {
    Write-Host "$installedName уже установлен."
} else {
    Write-Host "Установка $installedName..."

    winget install `
      --id $packageId `
      --exact `
      --version $version `
      --source winget `
      --installer-type inno `
      --architecture x64 `
      --accept-package-agreements `
      --accept-source-agreements `
      --silent

    if ($LASTEXITCODE -ne 0) {
        Write-Warning "Ошибка установки $installedName. Код завершения winget: $LASTEXITCODE. Пропускаем."
    } else {
        Write-Host "$installedName установлен успешно."
    }
}

# -----------------------------------------------------------------------------
# Приложение: Yandex Browser
# Репозиторий: https://github.com/microsoft/winget-pkgs/tree/master/manifests/y/Yandex/Browser
# -----------------------------------------------------------------------------

$packageId = "Yandex.Browser"
$version = "25.8.5.948"
$installedName = "Yandex Browser"

if (Test-AppInstalled -PackageId $packageId -InstalledName $installedName) {
    Write-Host "$installedName уже установлен."
} else {
    Write-Host "Установка $installedName..."

    winget install `
      --id $packageId `
      --exact `
      --version $version `
      --source winget `
      --architecture x64 `
      --accept-package-agreements `
      --accept-source-agreements `
      --silent `
      --custom "--do-not-launch-browser"

	if ($LASTEXITCODE -ne 0) { 
		Write-Warning "Ошибка установки $installedName. Код завершения работы winget: $LASTEXITCODE."
	} else { 
		Write-Host "$installedName установлен успешно."
	}
}

# -----------------------------------------------------------------------------
# Приложение: WhatsApp
# -----------------------------------------------------------------------------

$packageId = "9NKSQGP7F2NH"
$installedName = "WhatsApp"

if (Test-AppInstalled -PackageId $packageId -InstalledName $installedName) {
    Write-Host "$installedName уже установлен."
} else {
    Write-Host "Установка $installedName..."

    winget install `
      --id $packageId `
      --exact `
      --source msstore `
      --accept-package-agreements `
      --accept-source-agreements

    if ($LASTEXITCODE -ne 0) {
        Write-Warning "Ошибка установки $installedName. Код завершения winget: $LASTEXITCODE. Пропускаем."
    } else {
        Write-Host "$installedName установлен успешно."
    }
}

Write-Host "`nУстановка завершена.`n"
