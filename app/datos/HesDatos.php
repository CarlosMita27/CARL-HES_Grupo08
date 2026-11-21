<?php
/**
 * Acceso a datos de las Hojas de Entrada de Servicio (HES).
 */
final class HesDatos
{
    public const ESTADOS = ['Pendiente', 'Aprobada', 'Rechazada', 'Anulada', 'Retirada'];

    /** Busca HES por texto, estado y periodo; los filtros vacíos no se aplican. */
    public static function buscar(string $texto, string $estado, string $periodo): array
    {
        return Conexion::llamar('sp_hes_buscar', [$texto, $estado, $periodo]);
    }

    /** Detalle de una HES con su contrato, contratista, analista e inspección. */
    public static function detalle(string $numHes): ?array
    {
        return Conexion::llamarFila('sp_hes_detalle', [$numHes]);
    }

    /** Observaciones registradas para una HES. */
    public static function observaciones(string $numHes): array
    {
        return Conexion::llamar('sp_hes_observaciones', [$numHes]);
    }

    /** Número sugerido para la siguiente HES. */
    public static function siguienteNumero(): string
    {
        return (string) (Conexion::llamarFila('sp_hes_siguiente_numero')['Num_HES'] ?? '');
    }

    /** Registra una HES pendiente y su inspección; devuelve el número de inspección generado. */
    public static function registrar(string $numHes, ?string $fecha, ?string $monto, string $numContrato, string $periodo, string $firma): string
    {
        $fila = Conexion::llamarFila('sp_hes_registrar', [$numHes, $fecha, $monto, $numContrato, $periodo, $firma]);
        return (string) ($fila['Num_inspeccion'] ?? '');
    }

    /** Corrige la fecha de emisión y el monto de una HES pendiente. */
    public static function actualizar(string $numHes, ?string $fecha, ?string $monto): void
    {
        Conexion::llamar('sp_hes_actualizar', [$numHes, $fecha, $monto]);
    }

    /** Aprueba, rechaza o retira una HES pendiente. */
    public static function cambiarEstado(string $numHes, string $estado): void
    {
        Conexion::llamar('sp_hes_cambiar_estado', [$numHes, $estado]);
    }

    /** Eliminación lógica de una HES: queda en estado Anulada. */
    public static function anular(string $numHes): void
    {
        Conexion::llamar('sp_hes_anular', [$numHes]);
    }
}
