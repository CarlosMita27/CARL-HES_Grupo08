@echo off
chcp 65001 >nul
title CARL-HES - Preparar PHP portable
rem Copia en la carpeta "php" lo necesario del PHP de XAMPP, para que CARL-HES funcione sin XAMPP.
cd /d "%~dp0"
set "ORIGEN=C:\xampp\php"
if not exist "%ORIGEN%\php.exe" (
    echo No se encontró XAMPP en C:\xampp.
    set /p "ORIGEN=Escriba la carpeta de PHP, por ejemplo D:\xampp\php: "
)
if not exist "%ORIGEN%\php.exe" (
    echo No se encontró php.exe en "%ORIGEN%".
    pause
    exit /b 1
)
if not exist "%ORIGEN%\ext\php_mysqli.dll" (
    echo El PHP de "%ORIGEN%" no tiene la extensión mysqli.
    pause
    exit /b 1
)
echo Copiando PHP desde "%ORIGEN%" ...
robocopy "%ORIGEN%" "php" php.exe *.dll /NFL /NDL /NJH /NJS /NP >nul
if errorlevel 8 goto error
robocopy "%ORIGEN%\ext" "php\ext" *.dll /NFL /NDL /NJH /NJS /NP >nul
if errorlevel 8 goto error
for %%f in (vcruntime140.dll vcruntime140_1.dll msvcp140.dll) do (
    if exist "%SystemRoot%\System32\%%f" if not exist "php\%%f" copy /y "%SystemRoot%\System32\%%f" "php\" >nul
)
echo.
"php\php.exe" -n -d "extension_dir=\"%CD%\php\ext\"" -d extension=mysqli -r "echo 'PHP ' . PHP_VERSION . (extension_loaded('mysqli') ? ' con mysqli: listo.' : ' sin mysqli: revise la copia.') . PHP_EOL;"
echo La carpeta php quedó lista. CARL-HES.exe la usará automáticamente.
echo.
pause
exit /b 0
:error
echo No se pudo copiar PHP.
pause
exit /b 1
