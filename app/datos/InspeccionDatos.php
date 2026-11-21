<?php
/**
 * Acceso a datos de las inspecciones de obligaciones laborales.
 */
final class InspeccionDatos
{
    /** Busca inspecciones por número, HES o contratista, con filtro de periodo; los filtros vacíos no se aplican. */
    public static function buscar(string $texto, string $periodo): array
    {
        return Conexion::llamar('sp_inspeccion_buscar', [$texto, $periodo]);
    }
}
