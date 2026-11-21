<?php
/**
 * Acceso a datos de las contratistas.
 */
final class ContratistaDatos
{
    /** Busca contratistas por RUC o razón social. */
    public static function buscar(string $texto, bool $incluirInactivos): array
    {
        return Conexion::llamar('sp_contratista_buscar', [$texto, $incluirInactivos ? 1 : 0]);
    }

    /** Datos de una contratista; los teléfonos llegan como lista. */
    public static function obtener(string $ruc): ?array
    {
        $fila = Conexion::llamarFila('sp_contratista_obtener', [$ruc]);
        if ($fila) {
            $fila['Telefonos'] = $fila['Telefonos'] ? explode(',', $fila['Telefonos']) : [];
        }
        return $fila;
    }

    /** Registra una contratista con hasta tres teléfonos. */
    public static function insertar(string $ruc, string $razonSocial, array $telefonos): void
    {
        Conexion::llamar('sp_contratista_insertar', array_merge([$ruc, $razonSocial], self::tresTelefonos($telefonos)));
    }

    /** Actualiza la razón social y los teléfonos. */
    public static function actualizar(string $ruc, string $razonSocial, array $telefonos): void
    {
        Conexion::llamar('sp_contratista_actualizar', array_merge([$ruc, $razonSocial], self::tresTelefonos($telefonos)));
    }

    /** Eliminación lógica (Activo = 0). */
    public static function eliminar(string $ruc): void
    {
        Conexion::llamar('sp_contratista_eliminar', [$ruc]);
    }

    /** Vuelve a activar una contratista dada de baja. */
    public static function reactivar(string $ruc): void
    {
        Conexion::llamar('sp_contratista_reactivar', [$ruc]);
    }

    private static function tresTelefonos(array $telefonos): array
    {
        $telefonos = array_values($telefonos);
        return [$telefonos[0] ?? '', $telefonos[1] ?? '', $telefonos[2] ?? ''];
    }
}
