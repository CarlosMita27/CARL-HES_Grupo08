<?php
/**
 * Acceso a datos de los reportes de la Analista de Contratos.
 * Cada reporte se obtiene con un procedimiento almacenado; sus parámetros pueden ser
 * una analista, un periodo, una HES o una inspección.
 */
final class ReporteDatos
{
    public const CATALOGO = [
        1 => [
            'titulo'        => 'HES pendientes de una analista',
            'descripcion'   => 'HES pendientes de la analista elegida, de la más antigua a la más reciente, con los días que cada una lleva en espera.',
            'procedimiento' => 'sp_rep_hes_pendientes_analista',
            'parametros'    => ['analista'],
        ],
        2 => [
            'titulo'        => 'Carga de trabajo por analista',
            'descripcion'   => 'Contratos a cargo de cada analista vigente y cantidad de HES que tiene pendientes de revisión.',
            'procedimiento' => 'sp_rep_carga_analistas',
            'parametros'    => [],
        ],
        3 => [
            'titulo'        => 'Historial de observaciones de una HES',
            'descripcion'   => 'Observaciones registradas para una HES, en el orden en que se hicieron.',
            'procedimiento' => 'sp_rep_historial_observaciones',
            'parametros'    => ['hes'],
        ],
        4 => [
            'titulo'        => 'HES observadas más de una vez',
            'descripcion'   => 'HES que recibieron dos o más observaciones, con la fecha de la primera y de la última.',
            'procedimiento' => 'sp_rep_hes_observadas_reiteradas',
            'parametros'    => [],
        ],
        5 => [
            'titulo'        => 'Contratistas con HES por subsanar',
            'descripcion'   => 'Contratistas con HES pendientes que tienen observaciones, con sus teléfonos para coordinar la subsanación.',
            'procedimiento' => 'sp_rep_contratistas_por_subsanar',
            'parametros'    => [],
        ],
        6 => [
            'titulo'        => 'Inspecciones con documentación incompleta',
            'descripcion'   => 'Inspecciones del periodo sin firma de la contratista, sin reportes de las entidades o sin boletas de pago.',
            'procedimiento' => 'sp_rep_inspecciones_incompletas',
            'parametros'    => ['periodo'],
        ],
        7 => [
            'titulo'        => 'Conformidad de las obligaciones de una inspección',
            'descripcion'   => 'Compara lo declarado y pagado en el formato con lo que reportan las entidades. La conformidad se calcula, no se guarda.',
            'procedimiento' => 'sp_rep_conformidad_inspeccion',
            'parametros'    => ['inspeccion'],
        ],
        8 => [
            'titulo'        => 'Mora del periodo por contratista',
            'descripcion'   => 'Obligaciones del periodo pagadas con mora, por contratista y obligación.',
            'procedimiento' => 'sp_rep_mora_periodo',
            'parametros'    => ['periodo'],
        ],
        9 => [
            'titulo'        => 'HES pendientes con mora y su declaración jurada',
            'descripcion'   => 'HES pendientes cuya inspección tiene mora, con la situación de la declaración jurada de compromiso de pago.',
            'procedimiento' => 'sp_rep_hes_mora_declaracion',
            'parametros'    => [],
        ],
        10 => [
            'titulo'        => 'Pago de CTS y gratificación',
            'descripcion'   => 'Situación del pago de la CTS y de la gratificación en el periodo, para las HES de la analista elegida.',
            'procedimiento' => 'sp_rep_cts_gratificacion',
            'parametros'    => ['periodo', 'analista'],
        ],
        11 => [
            'titulo'        => 'Boletas sin firma frente a la obligación 2.2',
            'descripcion'   => 'Inspecciones que marcan como cumplida la entrega de boletas firmadas (obligación 2.2) y tienen boletas sin firma.',
            'procedimiento' => 'sp_rep_boletas_sin_firma',
            'parametros'    => [],
        ],
        12 => [
            'titulo'        => 'HES aprobadas para el memo de facturación',
            'descripcion'   => 'HES aprobadas del periodo para la analista elegida, con su contrato y centro de costo.',
            'procedimiento' => 'sp_rep_memo_facturacion',
            'parametros'    => ['periodo', 'analista'],
        ],
        13 => [
            'titulo'        => 'Monto aprobado por centro de costo',
            'descripcion'   => 'Cantidad de HES aprobadas y monto total por centro de costo en el periodo.',
            'procedimiento' => 'sp_rep_monto_centro_costo',
            'parametros'    => ['periodo'],
        ],
    ];

    /** Ejecuta el procedimiento del reporte con los valores de sus parámetros. */
    public static function ejecutar(int $numero, array $valores): array
    {
        $reporte = self::CATALOGO[$numero];
        $parametros = [];
        foreach ($reporte['parametros'] as $nombre) {
            $parametros[] = $valores[$nombre];
        }
        return Conexion::llamar($reporte['procedimiento'], $parametros);
    }

    /** Llamada del procedimiento con sus valores, para mostrarla debajo del reporte. */
    public static function llamada(int $numero, array $valores): string
    {
        $reporte = self::CATALOGO[$numero];
        $parametros = [];
        foreach ($reporte['parametros'] as $nombre) {
            $parametros[] = "'" . ($valores[$nombre] !== '' ? $valores[$nombre] : '…') . "'";
        }
        return $reporte['procedimiento'] . '(' . implode(', ', $parametros) . ')';
    }
}
