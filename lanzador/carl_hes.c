/*
 * CARL-HES: lanzador del aplicativo para Windows.
 *
 * 1. Busca PHP: carpeta "php" junto al ejecutable, XAMPP o la variable PATH.
 * 2. Inicia el servidor web de PHP, oculto, en un puerto libre de 127.0.0.1.
 * 3. Abre el aplicativo en una ventana propia de Microsoft Edge o Google Chrome
 *    (modo aplicación, sin barra de direcciones).
 * 4. Al cerrar la ventana, detiene el servidor de PHP.
 *
 * Proyecto académico del curso Gestión de Datos e Información (UCSM, 2026), Grupo 08.
 */
#define WIN32_LEAN_AND_MEAN
#include <winsock2.h>
#include <ws2tcpip.h>
#include <windows.h>
#include <shellapi.h>
#include <shlobj.h>
#include <stdarg.h>
#include <stdio.h>
#include <wchar.h>

#define TITULO L"CARL-HES"
#define RUTA 1024

static wchar_t carpeta[RUTA];
static wchar_t datos[RUTA];
static HANDLE trabajo;

static void mensaje(UINT tipo, const wchar_t *formato, ...)
{
    wchar_t texto[4096];
    va_list args;
    va_start(args, formato);
    _vsnwprintf(texto, 4095, formato, args);
    va_end(args);
    texto[4095] = 0;
    MessageBoxW(NULL, texto, TITULO, MB_OK | MB_SETFOREGROUND | tipo);
}

static BOOL existe(const wchar_t *ruta)
{
    DWORD a = GetFileAttributesW(ruta);
    return a != INVALID_FILE_ATTRIBUTES && !(a & FILE_ATTRIBUTE_DIRECTORY);
}

static void quitar_nombre(wchar_t *ruta)
{
    wchar_t *barra = wcsrchr(ruta, L'\\');
    if (barra) {
        *barra = 0;
    }
}

static BOOL buscar_php(wchar_t *php)
{
    const wchar_t *xampp[] = {L"C:\\xampp\\php\\php.exe", L"D:\\xampp\\php\\php.exe"};
    _snwprintf(php, RUTA, L"%ls\\php\\php.exe", carpeta);
    if (existe(php)) {
        return TRUE;
    }
    for (int i = 0; i < 2; i++) {
        if (existe(xampp[i])) {
            wcscpy(php, xampp[i]);
            return TRUE;
        }
    }
    return SearchPathW(NULL, L"php.exe", NULL, RUTA, php, NULL) > 0;
}

static BOOL buscar_navegador(wchar_t *navegador)
{
    const wchar_t *variables[] = {L"ProgramFiles(x86)", L"ProgramFiles", L"LocalAppData"};
    const wchar_t *programas[] = {L"Microsoft\\Edge\\Application\\msedge.exe",
                                  L"Google\\Chrome\\Application\\chrome.exe"};
    wchar_t base[RUTA];
    for (int p = 0; p < 2; p++) {
        for (int v = 0; v < 3; v++) {
            if (GetEnvironmentVariableW(variables[v], base, RUTA) > 0) {
                _snwprintf(navegador, RUTA, L"%ls\\%ls", base, programas[p]);
                if (existe(navegador)) {
                    return TRUE;
                }
            }
        }
    }
    return FALSE;
}

/* Intenta conectarse a 127.0.0.1:puerto con un tiempo máximo en milisegundos. */
static BOOL hay_servicio(int puerto, int espera)
{
    SOCKET s = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
    if (s == INVALID_SOCKET) {
        return FALSE;
    }
    u_long sin_bloqueo = 1;
    ioctlsocket(s, FIONBIO, &sin_bloqueo);
    struct sockaddr_in destino = {0};
    destino.sin_family = AF_INET;
    destino.sin_port = htons((u_short) puerto);
    destino.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
    connect(s, (struct sockaddr *) &destino, sizeof destino);
    fd_set escritura, error;
    FD_ZERO(&escritura);
    FD_ZERO(&error);
    FD_SET(s, &escritura);
    FD_SET(s, &error);
    struct timeval tiempo = {espera / 1000, (espera % 1000) * 1000};
    BOOL conectado = select(0, NULL, &escritura, &error, &tiempo) > 0 && FD_ISSET(s, &escritura);
    closesocket(s);
    return conectado;
}

static BOOL puerto_libre(int puerto)
{
    SOCKET s = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
    if (s == INVALID_SOCKET) {
        return FALSE;
    }
    struct sockaddr_in direccion = {0};
    direccion.sin_family = AF_INET;
    direccion.sin_port = htons((u_short) puerto);
    direccion.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
    BOOL libre = bind(s, (struct sockaddr *) &direccion, sizeof direccion) == 0;
    closesocket(s);
    return libre && !hay_servicio(puerto, 150);
}

typedef struct {
    DWORD proceso;
    BOOL hallada;
} Busqueda;

/* Ventana visible del navegador lanzado (clase Chrome_WidgetWin_ con título). */
static BOOL CALLBACK revisar_ventana(HWND ventana, LPARAM parametro)
{
    Busqueda *b = (Busqueda *) parametro;
    DWORD proceso = 0;
    GetWindowThreadProcessId(ventana, &proceso);
    if (proceso == b->proceso && IsWindowVisible(ventana)) {
        wchar_t clase[64], titulo[256];
        GetClassNameW(ventana, clase, 64);
        if (wcsncmp(clase, L"Chrome_WidgetWin_", 17) == 0 && GetWindowTextW(ventana, titulo, 256) > 0) {
            b->hallada = TRUE;
            return FALSE;
        }
    }
    return TRUE;
}

/* Perfil propio del navegador sin modo en segundo plano, para que se cierre con su ventana. */
static void preparar_perfil(const wchar_t *perfil)
{
    wchar_t estado[RUTA];
    _snwprintf(estado, RUTA, L"%ls\\Local State", perfil);
    if (existe(estado)) {
        return;
    }
    HANDLE f = CreateFileW(estado, GENERIC_WRITE, 0, NULL, CREATE_NEW, FILE_ATTRIBUTE_NORMAL, NULL);
    if (f != INVALID_HANDLE_VALUE) {
        const char *contenido = "{\"background_mode\":{\"enabled\":false}}";
        DWORD escritos;
        WriteFile(f, contenido, (DWORD) strlen(contenido), &escritos, NULL);
        CloseHandle(f);
    }
}

static BOOL iniciar(wchar_t *linea, HANDLE salida, BOOL oculto, PROCESS_INFORMATION *pi)
{
    STARTUPINFOW si = {0};
    si.cb = sizeof si;
    if (salida) {
        si.dwFlags = STARTF_USESTDHANDLES;
        si.hStdInput = GetStdHandle(STD_INPUT_HANDLE);
        si.hStdOutput = salida;
        si.hStdError = salida;
    }
    return CreateProcessW(NULL, linea, NULL, NULL, salida != NULL,
                          oculto ? CREATE_NO_WINDOW | CREATE_SUSPENDED : 0, NULL, carpeta, &si, pi);
}

int WINAPI wWinMain(HINSTANCE instancia, HINSTANCE anterior, PWSTR argumentos, int mostrar)
{
    (void) instancia; (void) anterior; (void) argumentos; (void) mostrar;

    HANDLE unico = CreateMutexW(NULL, TRUE, L"Local\\CARL-HES");
    if (GetLastError() == ERROR_ALREADY_EXISTS) {
        mensaje(MB_ICONINFORMATION, L"CARL-HES ya está abierto.\n\nBusque su ventana en la barra de tareas.");
        return 0;
    }

    GetModuleFileNameW(NULL, carpeta, RUTA);
    quitar_nombre(carpeta);

    wchar_t aplicativo[RUTA];
    _snwprintf(aplicativo, RUTA, L"%ls\\aplicativo", carpeta);
    wchar_t indice[RUTA];
    _snwprintf(indice, RUTA, L"%ls\\index.php", aplicativo);
    if (!existe(indice)) {
        mensaje(MB_ICONERROR, L"No se encontró la carpeta «aplicativo» junto a CARL-HES.exe.\n\n"
                              L"Copie la carpeta completa de CARL-HES, sin mover sus archivos.");
        return 1;
    }

    wchar_t php[RUTA];
    if (!buscar_php(php)) {
        mensaje(MB_ICONERROR, L"No se encontró PHP.\n\n"
                              L"CARL-HES busca PHP en este orden:\n"
                              L"  1. La carpeta «php» junto a CARL-HES.exe.\n"
                              L"  2. XAMPP (C:\\xampp\\php\\php.exe).\n"
                              L"  3. La variable PATH de Windows.\n\n"
                              L"Instale XAMPP o ejecute «Preparar PHP portable.bat» en una computadora que tenga XAMPP.");
        return 1;
    }
    wchar_t carpeta_php[RUTA];
    wcscpy(carpeta_php, php);
    quitar_nombre(carpeta_php);
    wchar_t mysqli[RUTA];
    _snwprintf(mysqli, RUTA, L"%ls\\ext\\php_mysqli.dll", carpeta_php);
    if (!existe(mysqli)) {
        mensaje(MB_ICONERROR, L"El PHP encontrado no tiene la extensión mysqli:\n%ls\n\n"
                              L"Falta el archivo ext\\php_mysqli.dll.", php);
        return 1;
    }

    WSADATA wsa;
    WSAStartup(MAKEWORD(2, 2), &wsa);

    int puerto = 0;
    for (int p = 8080; p <= 8099 && !puerto; p++) {
        if (puerto_libre(p)) {
            puerto = p;
        }
    }
    if (!puerto) {
        mensaje(MB_ICONERROR, L"Los puertos 8080 a 8099 están ocupados. Cierre otros servidores web e intente de nuevo.");
        return 1;
    }

    wchar_t base[RUTA];
    if (FAILED(SHGetFolderPathW(NULL, CSIDL_LOCAL_APPDATA, NULL, 0, base))) {
        GetTempPathW(RUTA, base);
    }
    _snwprintf(datos, RUTA, L"%ls\\CARL-HES", base);
    CreateDirectoryW(datos, NULL);
    wchar_t sesiones[RUTA], perfil[RUTA], registro[RUTA], errores[RUTA];
    _snwprintf(sesiones, RUTA, L"%ls\\sesiones", datos);
    _snwprintf(perfil, RUTA, L"%ls\\navegador", datos);
    _snwprintf(registro, RUTA, L"%ls\\servidor.log", datos);
    _snwprintf(errores, RUTA, L"%ls\\php_errores.log", datos);
    CreateDirectoryW(sesiones, NULL);
    CreateDirectoryW(perfil, NULL);

    trabajo = CreateJobObjectW(NULL, NULL);
    JOBOBJECT_EXTENDED_LIMIT_INFORMATION limite = {0};
    limite.BasicLimitInformation.LimitFlags = JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE;
    SetInformationJobObject(trabajo, JobObjectExtendedLimitInformation, &limite, sizeof limite);

    SECURITY_ATTRIBUTES heredable = {sizeof heredable, NULL, TRUE};
    HANDLE salida = CreateFileW(registro, GENERIC_WRITE, FILE_SHARE_READ | FILE_SHARE_WRITE, &heredable,
                                CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL);
    if (salida == INVALID_HANDLE_VALUE) {
        salida = NULL;
    }

    static wchar_t linea[8192];
    _snwprintf(linea, 8191,
               L"\"%ls\" -n -d \"extension_dir=\\\"%ls\\ext\\\"\" -d extension=mysqli"
               L" -d output_buffering=4096 -d default_charset=UTF-8 -d date.timezone=America/Lima"
               L" -d display_errors=0 -d log_errors=1 -d \"error_log=\\\"%ls\\\"\""
               L" -d \"session.save_path=\\\"%ls\\\"\" -S 127.0.0.1:%d -t \"%ls\"",
               php, carpeta_php, errores, sesiones, puerto, aplicativo);
    PROCESS_INFORMATION servidor;
    if (!iniciar(linea, salida, TRUE, &servidor)) {
        mensaje(MB_ICONERROR, L"No se pudo iniciar PHP (error %lu):\n%ls", GetLastError(), php);
        return 1;
    }
    AssignProcessToJobObject(trabajo, servidor.hProcess);
    ResumeThread(servidor.hThread);

    BOOL listo = FALSE;
    for (int i = 0; i < 100 && !listo; i++) {
        if (WaitForSingleObject(servidor.hProcess, 0) == WAIT_OBJECT_0) {
            DWORD codigo = 0;
            GetExitCodeProcess(servidor.hProcess, &codigo);
            if (codigo == 0xC0000135) {
                mensaje(MB_ICONERROR, L"PHP no pudo iniciarse porque falta un componente de Windows.\n\n"
                                      L"Instale «Microsoft Visual C++ Redistributable 2015-2022 (x64)» y vuelva a abrir CARL-HES.");
            } else {
                mensaje(MB_ICONERROR, L"El servidor de PHP se detuvo al iniciar (código %lu).\n\nRevise el archivo:\n%ls",
                        codigo, registro);
            }
            return 1;
        }
        listo = hay_servicio(puerto, 100);
        if (!listo) {
            Sleep(100);
        }
    }
    if (!listo) {
        mensaje(MB_ICONERROR, L"El servidor de PHP no respondió en el puerto %d.\n\nRevise el archivo:\n%ls", puerto, registro);
        return 1;
    }

    const wchar_t *pagina = L"index.php";
    if (!hay_servicio(3306, 600)) {
        pagina = L"conexion.php";
        mensaje(MB_ICONWARNING, L"No se detectó MySQL en el puerto 3306.\n\n"
                                L"Inicie el servicio MySQL80 (Servicios de Windows) o instale MySQL Server 8.0 y la base de datos "
                                L"con «Instalar base de datos.bat».\n\n"
                                L"CARL-HES se abrirá en la página «Prueba de conexión».");
    }
    wchar_t direccion[256];
    _snwprintf(direccion, 255, L"http://127.0.0.1:%d/%ls", puerto, pagina);

    wchar_t navegador[RUTA];
    BOOL abierta = FALSE;
    BOOL ventana_propia = FALSE;
    if (buscar_navegador(navegador)) {
        preparar_perfil(perfil);
        _snwprintf(linea, 8191,
                   L"\"%ls\" --app=%ls --user-data-dir=\"%ls\" --start-maximized --no-first-run"
                   L" --no-default-browser-check --disable-sync --hide-crash-restore-bubble"
                   L" --disable-features=Translate",
                   navegador, direccion, perfil);
        PROCESS_INFORMATION ventana;
        if (iniciar(linea, NULL, FALSE, &ventana)) {
            abierta = TRUE;
            DWORD inicio = GetTickCount();
            BOOL vista = FALSE;
            int ausente = 0;
            while (WaitForSingleObject(ventana.hProcess, 1000) == WAIT_TIMEOUT) {
                Busqueda b = {ventana.dwProcessId, FALSE};
                EnumWindows(revisar_ventana, (LPARAM) &b);
                if (b.hallada) {
                    vista = TRUE;
                    ausente = 0;
                } else if (vista && ++ausente >= 5) {
                    TerminateProcess(ventana.hProcess, 0);
                    break;
                }
            }
            ventana_propia = vista || GetTickCount() - inicio > 4000;
            CloseHandle(ventana.hThread);
            CloseHandle(ventana.hProcess);
        }
    }
    if (!abierta) {
        ShellExecuteW(NULL, L"open", direccion, NULL, NULL, SW_SHOWNORMAL);
    }
    if (!ventana_propia) {
        mensaje(MB_ICONINFORMATION, L"CARL-HES está abierto en su navegador:\n%ls\n\n"
                                    L"Cuando termine de usar el aplicativo, presione Aceptar para detener el servidor.", direccion);
    }

    TerminateJobObject(trabajo, 0);
    CloseHandle(trabajo);
    if (salida) {
        CloseHandle(salida);
    }
    WSACleanup();
    ReleaseMutex(unico);
    return 0;
}
