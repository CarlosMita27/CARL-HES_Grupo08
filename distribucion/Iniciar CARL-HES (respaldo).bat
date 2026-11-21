@echo off
chcp 65001 >nul
title CARL-HES - servidor del aplicativo
rem Alternativa a CARL-HES.exe: inicia el servidor de PHP y abre CARL-HES en el navegador predeterminado.
cd /d "%~dp0CARL-HES"
set "PHP=%CD%\php\php.exe"
if not exist "%PHP%" set "PHP=C:\xampp\php\php.exe"
if not exist "%PHP%" (
    echo No se encontró PHP.
    echo Ejecute "CARL-HES\Preparar PHP portable.bat" en una computadora con XAMPP o instale XAMPP.
    pause
    exit /b 1
)
for %%i in ("%PHP%") do set "CARPETA_PHP=%%~dpi"
set "DATOS=%LOCALAPPDATA%\CARL-HES"
if not exist "%DATOS%\sesiones" mkdir "%DATOS%\sesiones"
echo CARL-HES está disponible en http://127.0.0.1:8080
echo No cierre esta ventana mientras use el aplicativo. Para detenerlo, ciérrela.
start "" cmd /c "timeout /t 2 /nobreak >nul & start http://127.0.0.1:8080"
"%PHP%" -n -d "extension_dir=\"%CARPETA_PHP%ext\"" -d extension=mysqli -d output_buffering=4096 -d date.timezone=America/Lima -d "session.save_path=\"%DATOS%\sesiones\"" -S 127.0.0.1:8080 -t "%CD%\aplicativo"
pause
