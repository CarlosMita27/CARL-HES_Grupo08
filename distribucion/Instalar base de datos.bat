@echo off
chcp 65001 >nul
title CARL-HES - Instalar base de datos
cd /d "%~dp0"
set "MYSQL="
for %%v in (8.0 8.4 9.0 9.1 9.2 9.3 9.4 9.5) do (
    if exist "%ProgramFiles%\MySQL\MySQL Server %%v\bin\mysql.exe" set "MYSQL=%ProgramFiles%\MySQL\MySQL Server %%v\bin\mysql.exe"
)
if not defined MYSQL (
    for /f "delims=" %%m in ('where mysql.exe 2^>nul') do if not defined MYSQL set "MYSQL=%%m"
)
if not defined MYSQL (
    echo No se encontró MySQL Server.
    echo Instale MySQL Server 8.0 y vuelva a ejecutar este archivo.
    echo.
    pause
    exit /b 1
)
echo ============================================================
echo  CARL-HES - Instalación de la base de datos hes_spcc
echo ============================================================
echo.
echo Cliente de MySQL: %MYSQL%
echo.
echo Se crearán las bases hes_spcc y hes_spcc_historico con los datos de prueba
echo y el usuario app_hes. Si ya existen, se vuelven a crear desde cero.
echo.
echo Escriba la contraseña del usuario root de MySQL y presione Enter.
"%MYSQL%" -u root -p --default-character-set=utf8mb4 < "base de datos\CARL-HES_base_de_datos.sql" > "%TEMP%\carl-hes-instalacion.txt"
if errorlevel 1 (
    echo.
    echo No se pudo instalar la base de datos.
    echo Revise la contraseña de root y que el servicio MySQL80 esté iniciado.
) else (
    echo.
    echo La base de datos se instaló correctamente. Ya puede abrir CARL-HES.
)
echo.
pause
