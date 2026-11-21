<?php
/**
 * Acceso a datos de las observaciones de las HES.
 */
final class ObservacionDatos
{
    public static function obtener(string $numHes, string $numObservacion): ?array
    {
        return Conexion::llamarFila('sp_observacion_obtener', [$numHes, $numObservacion]);
    }

    /** Registra una observación; devuelve su número dentro de la HES. */
    public static function registrar(string $numHes, ?string $fecha, string $comentario): int
    {
        $fila = Conexion::llamarFila('sp_observacion_registrar', [$numHes, $fecha, $comentario]);
        return (int) ($fila['Num_observacion'] ?? 0);
    }

    /** Corrige el comentario de una observación. */
    public static function actualizar(string $numHes, string $numObservacion, string $comentario): void
    {
        Conexion::llamar('sp_observacion_actualizar', [$numHes, $numObservacion, $comentario]);
    }
}
