<?php
/**
 * Acceso a datos de los contratos.
 */
final class ContratoDatos
{
    /** Busca contratos por número, RUC o razón social. */
    public static function buscar(string $texto, bool $incluirInactivos): array
    {
        return Conexion::llamar('sp_contrato_buscar', [$texto, $incluirInactivos ? 1 : 0]);
    }

    /** Datos de un contrato para editarlo. */
    public static function obtener(string $numContrato): ?array
    {
        return Conexion::llamarFila('sp_contrato_obtener', [$numContrato]);
    }

    public static function insertar(string $numContrato, ?string $montoTotal, string $ruc, string $codCentro, string $numRegistro): void
    {
        Conexion::llamar('sp_contrato_insertar', [$numContrato, $montoTotal, $ruc, $codCentro, $numRegistro]);
    }

    public static function actualizar(string $numContrato, ?string $montoTotal, string $codCentro, string $numRegistro): void
    {
        Conexion::llamar('sp_contrato_actualizar', [$numContrato, $montoTotal, $codCentro, $numRegistro]);
    }

    /** Eliminación lógica (Activo = 0). */
    public static function eliminar(string $numContrato): void
    {
        Conexion::llamar('sp_contrato_eliminar', [$numContrato]);
    }

    public static function reactivar(string $numContrato): void
    {
        Conexion::llamar('sp_contrato_reactivar', [$numContrato]);
    }
}
