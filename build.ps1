$ahk2exe = "$env:USERPROFILE\scoop\apps\autohotkey\current\Compiler\Ahk2Exe.exe"
$base    = "$env:USERPROFILE\scoop\apps\autohotkey\current\v2\AutoHotkey64.exe"
$in      = "BrownDust2 Beat Helper.ahk"
$out     = "BrownDust2 Beat Helper.exe"
$icon    = "BrownDust2 Beat Helper.ico"

Write-Host "Compiling $in → $out ..." -ForegroundColor Cyan
Write-Host "  Ahk2Exe: $ahk2exe" -ForegroundColor DarkGray
Write-Host "  Base:    $base" -ForegroundColor DarkGray

& $ahk2exe /in "$in" /out "$out" /icon "$icon" /base "$base" /compress 0 /silent

if (Test-Path "$out") {
    $size = (Get-Item "$out").Length
    Write-Host "✓ Build success! ($($size / 1KB -as [int]) KB)" -ForegroundColor Green
} else {
    Write-Host "✗ Build failed - output not found" -ForegroundColor Red
    exit 1
}
