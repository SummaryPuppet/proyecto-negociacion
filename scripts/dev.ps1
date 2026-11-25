<#
.SYNOPSIS
    Script de utilidad para ejecutar RepartoJusto en Android, Web (Chrome o Edge) o generar APK release.

.EXAMPLE
    .\scripts\dev.ps1
    Abre el menu interactivo.

.EXAMPLE
    .\scripts\dev.ps1 android
    .\scripts\dev.ps1 web
    .\scripts\dev.ps1 web -Device edge
    .\scripts\dev.ps1 apk
#>
[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [ValidateSet("menu", "android", "web", "apk", "help")]
    [string]$Accion = "menu",

    [Parameter(Position = 1)]
    [string]$Device = ""
)

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $PSScriptRoot

function Show-Usage {
    Write-Host ""
    Write-Host "Uso: .\scripts\dev.ps1 [accion] [-Device <id>]" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Acciones disponibles:"
    Write-Host "  menu     Muestra el menu interactivo (por defecto)"
    Write-Host "  android  Ejecuta la app en un dispositivo o emulador Android"
    Write-Host "  web      Ejecuta la app en Web (pregunta entre Chrome o Edge)"
    Write-Host "  apk      Ejecuta flutter clean, flutter pub get y flutter build apk --release"
    Write-Host "  help     Muestra esta ayuda"
    Write-Host ""
    Write-Host "Ejemplos:"
    Write-Host "  .\scripts\dev.ps1"
    Write-Host "  .\scripts\dev.ps1 android"
    Write-Host "  .\scripts\dev.ps1 android -Device emulator-5554"
    Write-Host "  .\scripts\dev.ps1 web"
    Write-Host "  .\scripts\dev.ps1 web -Device edge"
    Write-Host "  .\scripts\dev.ps1 apk"
    Write-Host ""
}

function Assert-FlutterAvailable {
    if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
        Write-Host "[ERROR] No se encontro 'flutter' en el PATH." -ForegroundColor Red
        exit 1
    }
}

function Invoke-FlutterCommand {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Titulo,

        [Parameter(Mandatory = $true)]
        [string[]]$Argumentos
    )

    Write-Host ""
    Write-Host "==> $Titulo" -ForegroundColor Cyan
    Write-Host "    flutter $($Argumentos -join ' ')" -ForegroundColor DarkGray

    & flutter @Argumentos
    if ($LASTEXITCODE -ne 0) {
        Write-Host ""
        Write-Host "[ERROR] Fallo el comando: flutter $($Argumentos -join ' ') (codigo $LASTEXITCODE)" -ForegroundColor Red
        exit $LASTEXITCODE
    }
}

function Get-FlutterDevicesJson {
    $rawLines = & flutter devices --machine 2>$null
    if ($LASTEXITCODE -ne 0 -or -not $rawLines) {
        return @()
    }

    $rawText = ($rawLines -join "`n").Trim()
    $startIdx = $rawText.IndexOf("[")
    $endIdx = $rawText.LastIndexOf("]")
    if ($startIdx -lt 0 -or $endIdx -lt $startIdx) {
        return @()
    }

    $jsonText = $rawText.Substring($startIdx, $endIdx - $startIdx + 1)
    try {
        $parsed = $jsonText | ConvertFrom-Json
        if ($null -eq $parsed) { return @() }
        return @($parsed)
    } catch {
        return @()
    }
}

function Resolve-AndroidDevice {
    param([string]$PreferredDevice = "")

    if (-not [string]::IsNullOrWhiteSpace($PreferredDevice)) {
        return $PreferredDevice.Trim()
    }

    Write-Host ""
    Write-Host "==> Buscando dispositivos Android..." -ForegroundColor Cyan
    $devices = Get-FlutterDevicesJson
    $matches = @($devices | Where-Object { $_.targetPlatform -like "android*" })

    if ($matches.Count -eq 0) {
        Write-Host "[AVISO] No se detectaron dispositivos ni emuladores Android conectados." -ForegroundColor Yellow
        Write-Host "Emuladores disponibles:" -ForegroundColor DarkGray
        & flutter emulators
        Write-Host ""
        Write-Host "Conecta un dispositivo por USB (depuracion USB) o inicia un emulador y vuelve a intentar." -ForegroundColor Yellow
        return $null
    }

    if ($matches.Count -eq 1) {
        $chosen = $matches[0]
        Write-Host "    Dispositivo seleccionado: $($chosen.name) ($($chosen.id))" -ForegroundColor Green
        return $chosen.id
    }

    Write-Host "Se encontraron varios dispositivos Android:" -ForegroundColor Cyan
    for ($i = 0; $i -lt $matches.Count; $i++) {
        $d = $matches[$i]
        Write-Host "  [$($i + 1)] $($d.name) ($($d.id)) - $($d.targetPlatform)"
    }
    $selection = Read-Host "Elige un numero (Enter para 1)"
    if ([string]::IsNullOrWhiteSpace($selection)) {
        return $matches[0].id
    }
    $index = 0
    if ([int]::TryParse($selection, [ref]$index) -and $index -ge 1 -and $index -le $matches.Count) {
        return $matches[$index - 1].id
    }

    Write-Host "[ERROR] Seleccion invalida." -ForegroundColor Red
    return $null
}

function Resolve-WebDevice {
    param([string]$PreferredDevice = "")

    if (-not [string]::IsNullOrWhiteSpace($PreferredDevice)) {
        return $PreferredDevice.Trim()
    }

    while ($true) {
        Write-Host ""
        Write-Host "Selecciona el navegador Web:" -ForegroundColor Cyan
        Write-Host "  1. Chrome (por defecto)"
        Write-Host "  2. Edge"
        $choice = (Read-Host "Elige una opcion (Enter para Chrome)").Trim().ToLowerInvariant()

        switch ($choice) {
            ""       { return "chrome" }
            "1"      { return "chrome" }
            "chrome" { return "chrome" }
            "2"      { return "edge" }
            "edge"   { return "edge" }
            default  { Write-Host "Opcion invalida. Elige 1 (Chrome) o 2 (Edge)." -ForegroundColor Yellow }
        }
    }
}

function Start-AndroidRun {
    param([string]$DeviceId)
    $target = Resolve-AndroidDevice -PreferredDevice $DeviceId
    if (-not $target) {
        exit 1
    }
    Invoke-FlutterCommand -Titulo "Ejecutando RepartoJusto en Android ($target)" -Argumentos @("run", "-d", $target)
}

function Start-WebRun {
    param([string]$DeviceId)
    $target = Resolve-WebDevice -PreferredDevice $DeviceId
    Invoke-FlutterCommand -Titulo "Ejecutando RepartoJusto en Web ($target)" -Argumentos @("run", "-d", $target)
}

function New-ReleaseApk {
    Invoke-FlutterCommand -Titulo "Limpiando proyecto (flutter clean)" -Argumentos @("clean")
    Invoke-FlutterCommand -Titulo "Obteniendo dependencias (flutter pub get)" -Argumentos @("pub", "get")
    Invoke-FlutterCommand -Titulo "Compilando APK Release (flutter build apk --release)" -Argumentos @("build", "apk", "--release")

    $apkPath = Join-Path $ProjectRoot "build\app\outputs\flutter-apk\app-release.apk"
    Write-Host ""
    if (Test-Path $apkPath) {
        $fileInfo = Get-Item $apkPath
        $sizeMb = [math]::Round($fileInfo.Length / 1MB, 2)
        Write-Host "[OK] APK generado correctamente:" -ForegroundColor Green
        Write-Host "     Ruta:   $apkPath" -ForegroundColor White
        Write-Host "     Tamano: $sizeMb MB" -ForegroundColor White
    } else {
        Write-Host "[OK] Build completado." -ForegroundColor Green
    }
}

function Show-InteractiveMenu {
    while ($true) {
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host "  RepartoJusto - Utilidades Flutter" -ForegroundColor Cyan
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host "  1. Correr en Android"
        Write-Host "  2. Correr en Web (Chrome / Edge)"
        Write-Host "  3. Crear APK Release (clean + pub get + build apk --release)"
        Write-Host "  0. Salir"
        Write-Host ""

        $opcion = (Read-Host "Selecciona una opcion").Trim()
        switch ($opcion) {
            "1" { Start-AndroidRun -DeviceId $Device }
            "2" { Start-WebRun -DeviceId $Device }
            "3" { New-ReleaseApk }
            "0" { return }
            default { Write-Host "Opcion invalida. Elige 1, 2, 3 o 0." -ForegroundColor Yellow }
        }
    }
}

Push-Location $ProjectRoot
try {
    if ($Accion -eq "help") {
        Show-Usage
        exit 0
    }

    Assert-FlutterAvailable

    switch ($Accion) {
        "android" { Start-AndroidRun -DeviceId $Device }
        "web"     { Start-WebRun -DeviceId $Device }
        "apk"     { New-ReleaseApk }
        "menu"    { Show-InteractiveMenu }
    }
} finally {
    Pop-Location
}
