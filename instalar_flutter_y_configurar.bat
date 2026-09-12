@echo off
setlocal enabledelayedexpansion
set "FLUTTER_DIR=%USERPROFILE%\flutter"
set "PROJECT_DIR=%~dp0"

echo ============================================
echo   ControlaTodo - instalar Flutter y configurar
echo ============================================
echo.

where git >nul 2>nul
if errorlevel 1 (
    echo [ERROR] No se encontro "git" en este equipo.
    echo Instala Git desde https://git-scm.com/download/win
    echo y vuelve a ejecutar este archivo.
    pause
    exit /b 1
)

if exist "%FLUTTER_DIR%\bin\flutter.bat" (
    echo Flutter ya esta en "%FLUTTER_DIR%", se usara esa copia.
) else (
    if exist "%FLUTTER_DIR%" (
        echo [ERROR] La carpeta "%FLUTTER_DIR%" ya existe pero no parece
        echo         una instalacion valida de Flutter. Borrala manualmente
        echo         y vuelve a ejecutar este archivo.
        pause
        exit /b 1
    )
    echo [1/4] Descargando Flutter en "%FLUTTER_DIR%" (puede tardar varios minutos)...
    git clone -b stable --depth 1 https://github.com/flutter/flutter.git "%FLUTTER_DIR%"
    if errorlevel 1 (
        echo [ERROR] Fallo la descarga de Flutter. Revisa tu conexion a internet.
        pause
        exit /b 1
    )
)

rem Esto solo cambia el PATH de ESTA ventana, no toca la configuracion
rem permanente de Windows.
set "PATH=%FLUTTER_DIR%\bin;%PATH%"

echo.
echo [2/4] Ejecutando "flutter doctor" (primera vez puede tardar, descarga el SDK de Dart)...
call flutter doctor

echo.
echo [3/4] Generando carpetas android/ e ios/ del proyecto...
echo       (si pregunta por sobrescribir pubspec.yaml, analysis_options.yaml
echo        o lib/main.dart, responde N para NO sobrescribir)
cd /d "%PROJECT_DIR%"
call flutter create --org com.tuempresa --project-name controlatodo .
if errorlevel 1 (
    echo [ERROR] "flutter create" fallo. Revisa el mensaje de arriba.
    pause
    exit /b 1
)

echo.
echo [4/4] Instalando dependencias con "flutter pub get"...
call flutter pub get

echo.
echo ============================================
echo   Listo. Notas importantes:
echo.
echo   - Flutter quedo instalado en: %FLUTTER_DIR%
echo     Para poder escribir "flutter" en cualquier ventana nueva de
echo     terminal (sin usar este script), agrega esa ruta + \bin a tu
echo     PATH desde Windows: busca "Variables de entorno" en el menu
echo     inicio -> Editar las variables de entorno del sistema ->
echo     Variables de entorno -> en "Path" del usuario, agrega:
echo     %FLUTTER_DIR%\bin
echo.
echo   - Pasos que TODAVIA debes hacer a mano:
echo     1. Descarga google-services.json desde Firebase Console
echo        y colocalo en android\app\google-services.json
echo     2. Aplica los cambios de build.gradle y AndroidManifest.xml
echo        que estan en README.md (seccion 5)
echo     3. Ejecuta: flutter run
echo ============================================
pause
