param(
  [ValidateSet("run", "build")]
  [string]$Mode = "run"
)

$ErrorActionPreference = "Stop"

function Require-Command($name) {
  if (-not (Get-Command $name -ErrorAction SilentlyContinue)) {
    throw "لم يتم العثور على الأمر '$name'. ثبّت Flutter وأضفه إلى PATH أولًا."
  }
}

Require-Command "flutter"

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $projectRoot

Write-Host "Checking Windows platform files..." -ForegroundColor Yellow

if (-not (Test-Path ".\windows\runner\main.cpp")) {
  Write-Host "Windows runner files are missing. Generating platform files..." -ForegroundColor Yellow
  flutter create . --platforms=windows,web
}

Write-Host "Fetching packages..." -ForegroundColor Yellow
flutter pub get

if ($Mode -eq "build") {
  Write-Host "Building Windows release..." -ForegroundColor Green
  flutter build windows --release
  Write-Host "Build finished. EXE should be under build\windows\x64\runner\Release" -ForegroundColor Green
} else {
  Write-Host "Running Windows desktop app..." -ForegroundColor Green
  flutter run -d windows
}
