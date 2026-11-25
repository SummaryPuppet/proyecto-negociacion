@echo off
setlocal EnableExtensions EnableDelayedExpansion

for %%I in ("%~dp0..") do set "PROJECT_ROOT=%%~fI"
pushd "%PROJECT_ROOT%" >nul

set "ACTION=menu"
set "DEVICE="
set "EXIT_CODE=0"

:parse_args
if "%~1"=="" goto :args_done
if /I "%~1"=="menu" (
    set "ACTION=menu"
    shift
    goto :parse_args
)
if /I "%~1"=="android" (
    set "ACTION=android"
    shift
    goto :parse_args
)
if /I "%~1"=="web" (
    set "ACTION=web"
    shift
    goto :parse_args
)
if /I "%~1"=="apk" (
    set "ACTION=apk"
    shift
    goto :parse_args
)
if /I "%~1"=="help" (
    set "ACTION=help"
    shift
    goto :parse_args
)
if "%~1"=="/?" (
    set "ACTION=help"
    shift
    goto :parse_args
)
if /I "%~1"=="-h" (
    set "ACTION=help"
    shift
    goto :parse_args
)
if /I "%~1"=="--help" (
    set "ACTION=help"
    shift
    goto :parse_args
)
if /I "%~1"=="-d" (
    if "%~2"=="" (
        echo [ERROR] Falta el valor para -d.
        set "EXIT_CODE=1"
        goto :cleanup
    )
    set "DEVICE=%~2"
    shift
    shift
    goto :parse_args
)
if /I "%~1"=="--device" (
    if "%~2"=="" (
        echo [ERROR] Falta el valor para --device.
        set "EXIT_CODE=1"
        goto :cleanup
    )
    set "DEVICE=%~2"
    shift
    shift
    goto :parse_args
)
if not "%ACTION%"=="menu" if "%DEVICE%"=="" (
    set "DEVICE=%~1"
    shift
    goto :parse_args
)
echo [ERROR] Argumento no reconocido: %~1
call :show_usage
set "EXIT_CODE=1"
goto :cleanup

:args_done
if /I "%ACTION%"=="help" (
    call :show_usage
    goto :cleanup
)

where flutter >nul 2>&1
if errorlevel 1 (
    echo [ERROR] No se encontro 'flutter' en el PATH.
    set "EXIT_CODE=1"
    goto :cleanup
)

if /I "%ACTION%"=="android" (
    call :run_android "%DEVICE%"
    set "EXIT_CODE=!errorlevel!"
    goto :cleanup
)
if /I "%ACTION%"=="web" (
    call :run_web "%DEVICE%"
    set "EXIT_CODE=!errorlevel!"
    goto :cleanup
)
if /I "%ACTION%"=="apk" (
    call :build_apk
    set "EXIT_CODE=!errorlevel!"
    goto :cleanup
)

:menu_loop
echo.
echo ========================================
echo   RepartoJusto - Utilidades Flutter
echo ========================================
echo   1. Correr en Android
echo   2. Correr en Web (Chrome / Edge)
echo   3. Crear APK Release (clean + pub get + build apk --release)
echo   0. Salir
echo.
set "OPTION="
set /p "OPTION=Selecciona una opcion: "
if defined OPTION set "OPTION=%OPTION: =%"
if "%OPTION%"=="1" (
    call :run_android "%DEVICE%"
    goto :menu_loop
)
if "%OPTION%"=="2" (
    call :run_web "%DEVICE%"
    goto :menu_loop
)
if "%OPTION%"=="3" (
    call :build_apk
    goto :menu_loop
)
if "%OPTION%"=="0" (
    goto :cleanup
)
echo Opcion invalida. Elige 1, 2, 3 o 0.
goto :menu_loop

:show_usage
echo.
echo Uso: scripts\dev.bat [accion] [-d ^<device_id^>]
echo.
echo Acciones disponibles:
echo   menu     Muestra el menu interactivo (por defecto)
echo   android  Ejecuta la app en un dispositivo o emulador Android
echo   web      Ejecuta la app en Web (pregunta entre Chrome o Edge)
echo   apk      Ejecuta flutter clean, flutter pub get y flutter build apk --release
echo   help     Muestra esta ayuda
echo.
echo Ejemplos:
echo   scripts\dev.bat
echo   scripts\dev.bat android
echo   scripts\dev.bat android -d emulator-5554
echo   scripts\dev.bat web
echo   scripts\dev.bat web -d edge
echo   scripts\dev.bat apk
echo.
exit /b 0

:run_android
set "TARGET_DEV=%~1"
if not "%TARGET_DEV%"=="" goto :exec_android

echo.
echo ==^> Buscando dispositivos Android...
set "ANDROID_COUNT=0"
for /f "tokens=1,2,3 delims=|" %%A in ('powershell -NoProfile -Command "$raw = (& flutter devices --machine 2>$null) -join ''; $s = $raw.IndexOf('['); $e = $raw.LastIndexOf(']'); if ($s -ge 0 -and $e -gt $s) { ($raw.Substring($s, $e - $s + 1) | ConvertFrom-Json) | Where-Object { $_.targetPlatform -like 'android*' } | ForEach-Object { '{0}|{1}|{2}' -f $_.id, $_.name, $_.targetPlatform } }" 2^>nul') do (
    set /a ANDROID_COUNT+=1
    set "ANDROID_ID_!ANDROID_COUNT!=%%A"
    set "ANDROID_NAME_!ANDROID_COUNT!=%%B"
    set "ANDROID_PLAT_!ANDROID_COUNT!=%%C"
)

if %ANDROID_COUNT% EQU 0 (
    echo [AVISO] No se detectaron dispositivos ni emuladores Android conectados.
    echo Emuladores disponibles:
    call flutter emulators
    echo.
    echo Conecta un dispositivo por USB ^(depuracion USB^) o inicia un emulador y vuelve a intentar.
    exit /b 1
)

if %ANDROID_COUNT% EQU 1 (
    set "TARGET_DEV=!ANDROID_ID_1!"
    echo     Dispositivo seleccionado: !ANDROID_NAME_1! ^(!TARGET_DEV!^)
    goto :exec_android
)

echo Se encontraron varios dispositivos Android:
for /L %%I in (1,1,%ANDROID_COUNT%) do (
    echo   [%%I] !ANDROID_NAME_%%I! ^(!ANDROID_ID_%%I!^) - !ANDROID_PLAT_%%I!
)
set "DEV_CHOICE="
set /p "DEV_CHOICE=Elige un numero (Enter para 1): "
if "%DEV_CHOICE%"=="" set "DEV_CHOICE=1"
if defined ANDROID_ID_%DEV_CHOICE% (
    call set "TARGET_DEV=%%ANDROID_ID_%DEV_CHOICE%%%"
    goto :exec_android
)
echo [ERROR] Seleccion invalida.
exit /b 1

:exec_android
echo.
echo ==^> Ejecutando RepartoJusto en Android ^(%TARGET_DEV%^)
echo     flutter run -d %TARGET_DEV%
call flutter run -d "%TARGET_DEV%"
exit /b %errorlevel%

:run_web
set "TARGET_WEB=%~1"
if not "%TARGET_WEB%"=="" goto :exec_web

:ask_web_browser
echo.
echo Selecciona el navegador Web:
echo   1. Chrome (por defecto)
echo   2. Edge
set "WEB_CHOICE="
set /p "WEB_CHOICE=Elige una opcion (Enter para Chrome): "
if defined WEB_CHOICE set "WEB_CHOICE=%WEB_CHOICE: =%"
if "%WEB_CHOICE%"=="" (
    set "TARGET_WEB=chrome"
    goto :exec_web
)
if "%WEB_CHOICE%"=="1" (
    set "TARGET_WEB=chrome"
    goto :exec_web
)
if /I "%WEB_CHOICE%"=="chrome" (
    set "TARGET_WEB=chrome"
    goto :exec_web
)
if "%WEB_CHOICE%"=="2" (
    set "TARGET_WEB=edge"
    goto :exec_web
)
if /I "%WEB_CHOICE%"=="edge" (
    set "TARGET_WEB=edge"
    goto :exec_web
)
echo Opcion invalida. Elige 1 (Chrome) o 2 (Edge).
goto :ask_web_browser

:exec_web
echo.
echo ==^> Ejecutando RepartoJusto en Web ^(%TARGET_WEB%^)
echo     flutter run -d %TARGET_WEB%
call flutter run -d "%TARGET_WEB%"
exit /b %errorlevel%

:build_apk
echo.
echo ==^> Limpiando proyecto (flutter clean)
echo     flutter clean
call flutter clean
if errorlevel 1 (
    echo [ERROR] Fallo flutter clean.
    exit /b 1
)

echo.
echo ==^> Obteniendo dependencias (flutter pub get)
echo     flutter pub get
call flutter pub get
if errorlevel 1 (
    echo [ERROR] Fallo flutter pub get.
    exit /b 1
)

echo.
echo ==^> Compilando APK Release (flutter build apk --release)
echo     flutter build apk --release
call flutter build apk --release
if errorlevel 1 (
    echo [ERROR] Fallo flutter build apk --release.
    exit /b 1
)

set "APK_PATH=%PROJECT_ROOT%\build\app\outputs\flutter-apk\app-release.apk"
echo.
if exist "%APK_PATH%" (
    for %%F in ("%APK_PATH%") do set "APK_BYTES=%%~zF"
    echo [OK] APK generado correctamente:
    echo      Ruta:   %APK_PATH%
    echo      Bytes:  !APK_BYTES!
) else (
    echo [OK] Build completado.
)
exit /b 0

:cleanup
popd >nul
exit /b %EXIT_CODE%
