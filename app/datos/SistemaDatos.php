<?php
/**
 * Acceso a datos generales: prueba de conexión, panel de inicio y periodos.
 */
final class SistemaDatos
{
    /** Datos del servidor y de la base, sobre una conexión ya abierta. */
    public static function infoConexion(mysqli $cn): ?array
    {
        return Conexion::llamarCon($cn, 'sp_info_conexion')[0] ?? null;
    }

    /** Indicadores del panel de inicio. */
    public static function resumen(): ?array
    {
        return Conexion::llamarFila('sp_resumen_inicio');
    }

    /** Cantidad y monto de HES por estado. */
    public static function hesPorEstado(): array
    {
        return Conexion::llamar('sp_hes_por_estado');
    }

    /** Últimas HES emitidas. */
    public static function hesRecientes(int $cantidad): array
    {
        return Conexion::llamar('sp_hes_recientes', [$cantidad]);
    }

    /** Periodos (aaaamm) con inspecciones registradas. */
    public static function periodos(): array
    {
        return array_column(Conexion::llamar('sp_periodo_listar'), 'Periodo');
    }
}
