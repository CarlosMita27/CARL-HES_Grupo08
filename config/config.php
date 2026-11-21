<?php
/**
 * Datos de conexión con la base de datos hes_spcc.
 *
 * El aplicativo usa el usuario app_hes, que solo tiene permiso para
 * ejecutar procedimientos almacenados (lo crea el script 05).
 */
return [
    'servidor' => '127.0.0.1',
    'puerto'   => 3306,
    'base'     => 'hes_spcc',
    'usuario'  => 'app_hes',
    'clave'    => 'HesApp2026#',
];
