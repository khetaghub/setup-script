$ErrorActionPreference = "Stop"

$scriptUrl = "https://raw.githubusercontent.com/khetaghub/windows-setup-script/develop/setup-script.ps1"

Write-Host "Downloading setup script..."
$scriptContent = Invoke-WebRequest -Uri $scriptUrl -UseBasicParsing | Select-Object -ExpandProperty Content

Invoke-Expression $scriptContent
