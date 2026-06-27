$ErrorActionPreference = "Stop"

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$RepositoryUrl = "https://github.com/khetaghub/windows-setup-script.git"
$RepositoryName = "windows-setup-script"

$targetDir = Join-Path (Get-Location) $RepositoryName
$setupBat = Join-Path $targetDir "setup.bat"

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
        [ValidateSet("OK", "WARN", "INFO")]
        [string] $Type,

        [Parameter(Mandatory = $true)]
        [string] $Message
    )

    $color = switch ($Type) {
        "OK" { "Green" }
        "WARN" { "Yellow" }
        default { "Gray" }
    }

    Write-Host ("[{0}] {1}" -f $Type, $Message) -ForegroundColor $color
}

Write-Host "Windows Setup Script" -ForegroundColor Cyan

Write-Section "Проверка окружения"

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Status -Type "WARN" -Message "Git не найден"
    Write-Status -Type "INFO" -Message "Устанавливаю Git через winget..."

    winget install --id Git.Git --exact --source winget --accept-package-agreements --accept-source-agreements --disable-interactivity

    if ($LASTEXITCODE -ne 0) {
        Write-Status -Type "WARN" -Message "Не удалось установить Git. Код winget: $LASTEXITCODE"
        exit 1
    }

    $gitPath = Join-Path $env:ProgramFiles "Git\cmd"
    if (Test-Path $gitPath) {
        $env:PATH = "$gitPath;$env:PATH"
    }

    Write-Status -Type "OK" -Message "Git установлен"
} else {
    Write-Status -Type "OK" -Message "Git найден"
}

Write-Section "Клонирование репозитория"

git clone $RepositoryUrl $targetDir

if ($LASTEXITCODE -ne 0) {
    Write-Status -Type "WARN" -Message "Не удалось клонировать репозиторий. Код git: $LASTEXITCODE"
    exit 1
}

Write-Status -Type "OK" -Message "Репозиторий склонирован: $targetDir"

Write-Section "Запуск установки"
Write-Status -Type "INFO" -Message "Запускаю setup.bat"
& $setupBat
