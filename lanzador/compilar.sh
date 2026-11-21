#!/bin/sh
# Compila CARL-HES.exe desde Linux con MinGW-w64 (paquete gcc-mingw-w64-x86-64).
set -e
cd "$(dirname "$0")"
x86_64-w64-mingw32-windres -c 65001 recursos.rc -O coff -o recursos.o
x86_64-w64-mingw32-gcc -O2 -s -municode -mwindows -finput-charset=UTF-8 -Wall -Wextra \
    carl_hes.c recursos.o -o CARL-HES.exe -lws2_32 -lshell32 -luser32 -static-libgcc
rm -f recursos.o
echo "CARL-HES.exe compilado"
