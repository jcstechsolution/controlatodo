@echo off
setlocal
cd /d "%~dp0"

echo ============================================
echo   ControlaTodo - configuracion automatica
echo ============================================
echo Carpeta actual: %cd%
echo.

where flutter >nul 2>nul
if errorlevel 1 (
    echo [ERROR] No se encontro "flutter" en el PATH de este equipo.
    echo Instala Flutter desde https://docs.flutter.dev/get-started/install/windows
    echo y vuelve a ejecutar este archivo.
    echo.
    pause
    exit /b 1
)

echo [1/2] Generando carpetas android/ e ios/ con "flutter create"...
echo       (si pregunta por sobrescribir pubspec.yaml, analysis_options.yaml
echo        o lib/main.dart, responde N para NO sobrescribir)
call flutter create --org com.tuempresa --project-name controlatodo .
if errorlevel 1 (
    echo [ERROR] "flutter create" fallo. Revisa el mensaje de arriba.
    pause
    exit /b 1
)

echo.
echo [2/2] Instalando dependencias con "flutter pub get"...
call flutter pub get
if errorlevel 1 (
    echo [ERROR] "flutter pub get" fallo. Revisa el mensaje de arriba.
    pause
    exit /b 1
)

echo.
echo ============================================
echo   Listo. Pasos que TODAVIA debes hacer a mano:
echo   1. Descarga google-services.json desde Firebase Console
echo      y colocalo en android\app\google-services.json
echo   2. Aplica los cambios de build.gradle y AndroidManifest.xml
echo      que estan en README.md (seccion 5)
echo   3. Ejecuta: flutter run
echo ============================================
pause
