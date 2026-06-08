$root  = Split-Path -Parent $MyInvocation.MyCommand.Path
$ahk2exe = "$env:USERPROFILE\scoop\apps\autohotkey\current\Compiler\Ahk2Exe.exe"
$base    = "$env:USERPROFILE\scoop\apps\autohotkey\current\v2\AutoHotkey64.exe"

$in      = "src\BrownDust2 Beat Helper.ahk"
$out     = "BrownDust2 Beat Helper.exe"
$outDir  = Join-Path $root "dist"
$outPath = Join-Path $outDir $out
$icon    = Join-Path $root "assets\BrownDust2 Beat Helper.ico"

# Read version from language file
$verLine = Select-String -Path "$root\lang\zh-TW.ini" -Pattern "^version=" | Select-Object -First 1
$version = $verLine.Line -replace "^version=", ""

$zipName = "BrownDust2-Beat-Helper-$version.zip"
$zipPath = Join-Path $root "dist\$zipName"

# === Step 1: Compile .exe ===
Write-Host "Compiling $in → $out ..." -ForegroundColor Cyan
Write-Host "  Ahk2Exe: $ahk2exe" -ForegroundColor DarkGray
Write-Host "  Base:    $base" -ForegroundColor DarkGray

& $ahk2exe /in "$in" /out "$outPath" /icon "$icon" /base "$base" /compress 0 /silent

if (-not (Test-Path "$outPath")) {
    Write-Host "✗ Build failed - output not found" -ForegroundColor Red
    exit 1
}

$size = (Get-Item "$outPath").Length
Write-Host "✓ Build success! ($($size / 1KB -as [int]) KB)" -ForegroundColor Green

# === Step 2: Package .zip ===
Write-Host "Packaging $zipName ..." -ForegroundColor Cyan

Remove-Item -Path $zipPath -ErrorAction SilentlyContinue

# Stage files at zip root level
$stageDir = Join-Path $root "dist\_stage"
New-Item -ItemType Directory -Path $stageDir -Force | Out-Null
Copy-Item -Path $outPath -Destination $stageDir
Copy-Item -Path "$root\lang" -Destination $stageDir -Recurse

Compress-Archive -Path "$stageDir\*" -DestinationPath $zipPath
Remove-Item -Path $stageDir -Recurse -Force

$zipSize = (Get-Item $zipPath).Length
Write-Host "✓ Package created: dist\$zipName ($($zipSize / 1KB -as [int]) KB)" -ForegroundColor Green
