# -----------------------------------------------------------------------------
# Красивый вывод и кодировка
# -----------------------------------------------------------------------------

$ErrorActionPreference = "Stop"

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$script:TotalApps = 0
$script:CurrentApp = 0
$script:InstalledApps = 0
$script:SkippedApps = 0
$script:FailedApps = 0
$script:LogDir = Join-Path $PSScriptRoot "logs"
$script:LogFile = Join-Path $script:LogDir ("setup-winget-{0}.log" -f (Get-Date -Format "yyyyMMdd-HHmmss"))

function Write-Section {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Title
    )

    Write-Host ""
    Write-Host "== $Title ==" -ForegroundColor Cyan
}

function Write-Status {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("OK", "SKIP", "WARN", "INFO")]
        [string] $Type,

        [Parameter(Mandatory = $true)]
        [string] $Message
    )

    $color = switch ($Type) {
        "OK" { "Green" }
        "SKIP" { "DarkGray" }
        "WARN" { "Yellow" }
        default { "Gray" }
    }

    Write-Host ("[{0}] {1}" -f $Type, $Message) -ForegroundColor $color
}

function Invoke-WingetQuiet {
    param(
        [Parameter(Mandatory = $true)]
        [string[]] $Arguments
    )

    "" | Out-File -FilePath $script:LogFile -Append -Encoding utf8
    "winget $($Arguments -join ' ')" | Out-File -FilePath $script:LogFile -Append -Encoding utf8

    $output = & winget @Arguments 2>&1
    $exitCode = $LASTEXITCODE

    $output | Out-File -FilePath $script:LogFile -Append -Encoding utf8

    return [PSCustomObject]@{
        ExitCode = $exitCode
        Output = $output
    }
}

function Test-AppInstalled {
    param(
        [Parameter(Mandatory = $true)]
        [string] $PackageId,

        [Parameter(Mandatory = $false)]
        [string] $InstalledName,

        [Parameter(Mandatory = $false)]
        [string] $Source = "winget"
    )

    $args = @("list", "--id", $PackageId, "--exact", "--source", $Source, "--disable-interactivity")
    $result = Invoke-WingetQuiet -Arguments $args

    if ($result.ExitCode -eq 0) {
        return $true
    }

    if (-not [string]::IsNullOrWhiteSpace($InstalledName)) {
        $args = @("list", "--name", $InstalledName, "--disable-interactivity")
        $result = Invoke-WingetQuiet -Arguments $args

        if ($result.ExitCode -eq 0) {
            return $true
        }
    }

    return $false
}

function Install-App {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable] $App
    )

    $script:CurrentApp++

    $name = $App.Name
    $source = if ($App.Source) { $App.Source } else { "winget" }
    $versionText = if ($App.Version) { " $($App.Version)" } else { "" }
    $prefix = "[{0}/{1}]" -f $script:CurrentApp, $script:TotalApps

    Write-Host ""
    Write-Host "$prefix $name$versionText" -ForegroundColor White

    if (Test-AppInstalled -PackageId $App.Id -InstalledName $name -Source $source) {
        $script:SkippedApps++
        Write-Status -Type "SKIP" -Message "Уже установлен"
        return
    }

    Write-Status -Type "INFO" -Message "Устанавливаю через winget..."

    $args = @(
        "install",
        "--id", $App.Id,
        "--exact",
        "--source", $source,
        "--accept-package-agreements",
        "--accept-source-agreements",
        "--disable-interactivity"
    )

    if ($App.Version) {
        $args += @("--version", $App.Version)
    }

    if ($App.InstallerType) {
        $args += @("--installer-type", $App.InstallerType)
    }

    if ($App.Architecture) {
        $args += @("--architecture", $App.Architecture)
    }

    if ($App.Scope) {
        $args += @("--scope", $App.Scope)
    }

    if ($App.Silent -ne $false) {
        $args += "--silent"
    }

    if ($App.Custom) {
        $args += @("--custom", $App.Custom)
    }

    $result = Invoke-WingetQuiet -Arguments $args

    if ($result.ExitCode -ne 0) {
        $script:FailedApps++
        Write-Status -Type "WARN" -Message "Не удалось установить. Код winget: $($result.ExitCode). Подробности в логе."
        return
    }

    $script:InstalledApps++
    Write-Status -Type "OK" -Message "Установлен успешно"
}

# -----------------------------------------------------------------------------
# Подготовка папки логов
# -----------------------------------------------------------------------------

New-Item -ItemType Directory -Path $script:LogDir -Force | Out-Null

# -----------------------------------------------------------------------------
# Проверка окружения
# -----------------------------------------------------------------------------

Clear-Host
Write-Host "Windows Setup Script" -ForegroundColor Cyan
Write-Host "Лог winget: $script:LogFile" -ForegroundColor DarkGray

Write-Section "Проверка окружения"

$isAdmin = ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)

if (-not $isAdmin) {
    Write-Status -Type "WARN" -Message "Скрипт нужно запускать от имени администратора."
    Write-Host ""
    Write-Host "Решение: ПКМ по setup.bat -> Запуск от имени администратора" -ForegroundColor Yellow
    exit 1
}

Write-Status -Type "OK" -Message "Права администратора есть"

$wingetExists = Get-Command winget -ErrorAction SilentlyContinue
if (-not $wingetExists) {
    Write-Status -Type "WARN" -Message "winget не найден или не доступен в PATH."
    Write-Host ""
    Write-Host "Установи App Installer из Microsoft Store и перезапусти PowerShell." -ForegroundColor Yellow
    exit 1
}

Write-Status -Type "OK" -Message "winget найден"

# -----------------------------------------------------------------------------
# Настройки Проводника
# -----------------------------------------------------------------------------

Write-Section "Настройка Проводника"

$explorerAdvanced = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"

Set-ItemProperty -Path $explorerAdvanced -Name Hidden -Value 1
Set-ItemProperty -Path $explorerAdvanced -Name HideFileExt -Value 0

Stop-Process -Name explorer -ErrorAction SilentlyContinue
Start-Sleep -Milliseconds 500
Start-Process explorer.exe

Write-Status -Type "OK" -Message "Скрытые файлы и расширения включены"

# -----------------------------------------------------------------------------
# Приложения
# -----------------------------------------------------------------------------

$apps = @(
    @{
        Name = "Bitwarden"
        Id = "Bitwarden.Bitwarden"
        Version = "2026.3.1"
        InstallerType = "nullsoft"
        Architecture = "x64"
        Scope = "machine"
        Custom = "/allusers"
    },
    @{
        Name = "CapCut"
        Id = "ByteDance.CapCut"
        Version = "8.5.0.3590"
        Architecture = "x64"
    },
    @{
        Name = "Chocolatey"
        Id = "Chocolatey.Chocolatey"
        Version = "2.7.1.0"
        InstallerType = "wix"
        Scope = "machine"
    },
    @{
        Name = "Discord"
        Id = "Discord.Discord"
    },
    @{
        Name = "Epic Games Launcher"
        Id = "EpicGames.EpicGamesLauncher"
        Version = "1.3.161.0"
        InstallerType = "wix"
        Architecture = "x64"
        Scope = "machine"
    },
    @{
        Name = "Git"
        Id = "Git.Git"
        Version = "2.54.0"
        InstallerType = "inno"
        Architecture = "x64"
        Scope = "machine"
    },
    @{
        Name = "Notepad++"
        Id = "Notepad++.Notepad++"
        Version = "8.9.2"
        InstallerType = "wix"
        Architecture = "x64"
        Scope = "machine"
    },
    @{
        Name = "Notion"
        Id = "Notion.Notion"
        Version = "7.9.0"
        InstallerType = "nullsoft"
        Architecture = "x64"
    },
    @{
        Name = "Postman"
        Id = "Postman.Postman"
        Version = "12.7.6"
        Architecture = "x64"
    },
    @{
        Name = "qBittorrent"
        Id = "qBittorrent.qBittorrent"
        Version = "5.1.4"
        InstallerType = "nullsoft"
        Architecture = "x64"
        Scope = "machine"
    },
    @{
        Name = "Steam"
        Id = "Valve.Steam"
        Version = "2.10.91.91"
        InstallerType = "nullsoft"
        Scope = "machine"
    },
    @{
        Name = "Telegram Desktop"
        Id = "Telegram.TelegramDesktop"
        Version = "6.7.8"
        InstallerType = "inno"
        Architecture = "x64"
    },
    @{
        Name = "Yandex Browser"
        Id = "Yandex.Browser"
        Version = "25.8.5.948"
        Architecture = "x64"
        Custom = "--do-not-launch-browser"
    },
    @{
        Name = "WhatsApp"
        Id = "9NKSQGP7F2NH"
        Source = "msstore"
        Silent = $false
    }
)

$script:TotalApps = $apps.Count

Write-Section "Установка приложений"

foreach ($app in $apps) {
    Install-App -App $app
}

Write-Section "Готово"
Write-Status -Type "OK" -Message ("Установлено: {0}" -f $script:InstalledApps)
Write-Status -Type "SKIP" -Message ("Пропущено: {0}" -f $script:SkippedApps)

if ($script:FailedApps -gt 0) {
    Write-Status -Type "WARN" -Message ("Ошибки: {0}" -f $script:FailedApps)
} else {
    Write-Status -Type "OK" -Message "Ошибок нет"
}

Write-Host ""
$logPath = $script:LogFile
Write-Host ("Подробный лог: {0}" -f $logPath) -ForegroundColor DarkGray
