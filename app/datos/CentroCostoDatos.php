<?php
/**
 * Acceso a datos de los centros de costo.
 */
final class CentroCostoDatos
{
    /** Lista los centros de costo con la cantidad de contratos vigentes. */
    public static function listar(bool $incluirInactivos = false): array
    {
        return Conexion::llamar('sp_centro_costo_listar', [$incluirInactivos ? 1 : 0]);
    }

    public static function obtener(string $codigo): ?array
    {
        return Conexion::llamarFila('sp_centro_costo_obtener', [$codigo]);
    }

    public static function insertar(string $codigo, string $nombre): void
    {
        Conexion::llamar('sp_centro_costo_insertar', [$codigo, $nombre]);
    }

    public static function actualizar(string $codigo, string $nombre): void
    {
        Conexion::llamar('sp_centro_costo_actualizar', [$codigo, $nombre]);
    }

    /** Eliminación lógica (Activo = 0). */
    public static function eliminar(string $codigo): void
    {
        Conexion::llamar('sp_centro_costo_eliminar', [$codigo]);
    }

    public static function reactivar(string $codigo): void
    {
        Conexion::llamar('sp_centro_costo_reactivar', [$codigo]);
    }
}
