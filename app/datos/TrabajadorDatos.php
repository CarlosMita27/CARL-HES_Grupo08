<?php
/**
 * Acceso a datos de los trabajadores de las contratistas.
 */
final class TrabajadorDatos
{
    /** Busca trabajadores por DNI, apellidos, nombres o contratista. */
    public static function buscar(string $texto, bool $incluirInactivos = false): array
    {
        return Conexion::llamar('sp_trabajador_buscar', [$texto, $incluirInactivos ? 1 : 0]);
    }

    public static function obtener(string $dni): ?array
    {
        return Conexion::llamarFila('sp_trabajador_obtener', [$dni]);
    }

    public static function insertar(string $dni, string $apellidos, string $nombres, string $ruc): void
    {
        Conexion::llamar('sp_trabajador_insertar', [$dni, $apellidos, $nombres, $ruc]);
    }

    public static function actualizar(string $dni, string $apellidos, string $nombres): void
    {
        Conexion::llamar('sp_trabajador_actualizar', [$dni, $apellidos, $nombres]);
    }

    /** Eliminación lógica (Activo = 0). */
    public static function eliminar(string $dni): void
    {
        Conexion::llamar('sp_trabajador_eliminar', [$dni]);
    }

    public static function reactivar(string $dni): void
    {
        Conexion::llamar('sp_trabajador_reactivar', [$dni]);
    }
}
