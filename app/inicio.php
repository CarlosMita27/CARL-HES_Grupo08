<?php
/**
 * Carga común de todas las páginas: conexión, acceso a datos y plantilla.
 */
date_default_timezone_set('America/Lima');
if (session_status() === PHP_SESSION_NONE) {
    session_start();
}

require_once __DIR__ . '/Conexion.php';
require_once __DIR__ . '/funciones.php';
require_once __DIR__ . '/plantilla.php';
require_once __DIR__ . '/datos/SistemaDatos.php';
require_once __DIR__ . '/datos/ContratistaDatos.php';
require_once __DIR__ . '/datos/HesDatos.php';
require_once __DIR__ . '/datos/AnalistaDatos.php';
require_once __DIR__ . '/datos/ReporteDatos.php';
require_once __DIR__ . '/datos/ContratoDatos.php';
require_once __DIR__ . '/datos/CentroCostoDatos.php';
require_once __DIR__ . '/datos/ObservacionDatos.php';
require_once __DIR__ . '/datos/TrabajadorDatos.php';
require_once __DIR__ . '/datos/InspeccionDatos.php';
