# VStream - Windows Installation Script
# This script installs Git, Flutter, and sets up the VStream project.

$projectName = "vstream"
$repoUrl = "https://github.com/lucachak/Vstream.git"

Write-Host "--- VStream Project Setup for Windows ---" -ForegroundColor Cyan

# 1. Check/Install Git
if (!(Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "[!] Git not found. Installing via winget..." -ForegroundColor Yellow
    winget install --id Git.Git -e --source winget
} else {
    Write-Host "[✓] Git is already installed." -ForegroundColor Green
}

# 2. Check/Install Flutter
if (!(Get-Command flutter -ErrorAction SilentlyContinue)) {
    Write-Host "[!] Flutter not found. Installing via winget..." -ForegroundColor Yellow
    winget install --id Google.Flutter -e --source winget
    Write-Host "[!] Please restart your terminal after this script finishes to update the PATH." -ForegroundColor Red
} else {
    Write-Host "[✓] Flutter is already installed." -ForegroundColor Green
}

# 3. Clone Repository
if (!(Test-Path $projectName)) {
    Write-Host "[i] Cloning repository..." -ForegroundColor Cyan
    git clone $repoUrl
    cd $projectName
} else {
    Write-Host "[✓] Project directory already exists." -ForegroundColor Green
    cd $projectName
    Write-Host "[i] Pulling latest changes..." -ForegroundColor Cyan
    git pull
}

# 4. Install Dependencies
Write-Host "[i] Running flutter pub get..." -ForegroundColor Cyan
flutter pub get

# 5. Run Build Runner
Write-Host "[i] Generating code (Riverpod/Hive)..." -ForegroundColor Cyan
flutter pub run build_runner build --delete-conflicting-outputs

Write-Host "`n--- Setup Complete! ---" -ForegroundColor Green
Write-Host "To run the app, use: flutter run" -ForegroundColor White
