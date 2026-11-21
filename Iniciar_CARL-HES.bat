@echo off
chcp 65001 >nul
title CARL-HES - servidor de desarrollo
rem Inicia el servidor de PHP de XAMPP con esta carpeta y abre CARL-HES en el navegador.
set "PHP=C:\xampp\php\php.exe"
if not exist "%PHP%" (
    echo No se encontró PHP en %PHP%
    echo Edite este archivo y escriba la ruta de php.exe en la línea "set PHP=".
    pause
    exit /b 1
)
cd /d "%~dp0"
echo CARL-HES está disponible en http://127.0.0.1:8080
echo Para detenerlo, cierre esta ventana.
start "" cmd /c "timeout /t 2 /nobreak >nul & start http://127.0.0.1:8080"
"%PHP%" -S 127.0.0.1:8080
