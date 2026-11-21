<?php
/**
 * Acceso a datos de las analistas de contratos y de sus cargos.
 */
final class AnalistaDatos
{
    /** Lista las analistas con su cargo y la cantidad de contratos a cargo. */
    public static function listar(bool $incluirInactivos = false): array
    {
        return Conexion::llamar('sp_analista_listar', [$incluirInactivos ? 1 : 0]);
    }

    /** Cargos disponibles para las analistas. */
    public static function cargos(): array
    {
        return Conexion::llamar('sp_cargo_listar');
    }

    public static function obtener(string $numRegistro): ?array
    {
        return Conexion::llamarFila('sp_analista_obtener', [$numRegistro]);
    }

    public static function insertar(string $numRegistro, string $apellidos, string $nombres, string $codCargo): void
    {
        Conexion::llamar('sp_analista_insertar', [$numRegistro, $apellidos, $nombres, $codCargo]);
    }

    public static function actualizar(string $numRegistro, string $apellidos, string $nombres, string $codCargo): void
    {
        Conexion::llamar('sp_analista_actualizar', [$numRegistro, $apellidos, $nombres, $codCargo]);
    }

    /** Eliminación lógica (Activo = 0). */
    public static function eliminar(string $numRegistro): void
    {
        Conexion::llamar('sp_analista_eliminar', [$numRegistro]);
    }

    public static function reactivar(string $numRegistro): void
    {
        Conexion::llamar('sp_analista_reactivar', [$numRegistro]);
    }
}
