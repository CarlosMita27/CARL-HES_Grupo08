<?php
/**
 * Inicio: indicadores generales, HES por estado y últimas HES emitidas.
 */
require __DIR__ . '/app/inicio.php';

$error = null;
try {
    $resumen = SistemaDatos::resumen();
    $estados = SistemaDatos::hesPorEstado();
    $recientes = SistemaDatos::hesRecientes(6);
} catch (mysqli_sql_exception $e) {
    $error = $e;
}

encabezado('Inicio', 'inicio', 'Resumen de la revisión y liberación de las Hojas de Entrada de Servicio');

if ($error) {
    panel_error($error);
    pie();
    return;
}

$totalHes = max(1, (int) array_sum(array_column($estados, 'Cantidad')));
$indicadores = [
    ['hes', 'tono-azul', 'HES registradas', (string) $resumen['Hes_registradas'], 'En todos los periodos'],
    ['pendiente', 'tono-ambar', 'HES pendientes', (string) $resumen['Hes_pendientes'], 'Por revisar y liberar'],
    ['aprobada', 'tono-verde', 'HES aprobadas', (string) $resumen['Hes_aprobadas'], 'Liberadas para facturar'],
    ['monto', 'tono-cobre', 'Monto aprobado', moneda($resumen['Monto_aprobado']), 'Suma de las HES aprobadas'],
    ['contratistas', 'tono-gris', 'Contratistas activas', (string) $resumen['Contratistas_activos'], $resumen['Contratos_activos'] . ' contratos vigentes'],
    ['observaciones', 'tono-rojo', 'Observaciones', (string) $resumen['Observaciones'], 'Registradas por las analistas'],
];
?>
<section class="indicadores">
    <?php foreach ($indicadores as [$ico, $tono, $etiqueta, $valor, $nota]): ?>
        <article class="indicador">
            <span class="indicador-icono <?= $tono ?>"><?= icono($ico, 22) ?></span>
            <div>
                <p class="indicador-etiqueta"><?= e($etiqueta) ?></p>
                <p class="indicador-valor"><?= e($valor) ?></p>
                <p class="indicador-nota"><?= e($nota) ?></p>
            </div>
        </article>
    <?php endforeach; ?>
</section>
<?= fuente('sp_resumen_inicio()') ?>

<div class="rejilla-inicio">
    <section class="tarjeta">
        <header class="tarjeta-cabecera">
            <h2>HES por estado</h2>
            <span class="tarjeta-nota"><?= $totalHes ?> HES</span>
        </header>
        <ul class="barras">
            <?php foreach ($estados as $fila): ?>
                <?php $porcentaje = round($fila['Cantidad'] * 100 / $totalHes, 1); ?>
                <li>
                    <span class="barras-etiqueta"><?= insignia_estado($fila['Estado']) ?></span>
                    <span class="barras-pista">
                        <span class="barras-relleno relleno-<?= e(strtolower($fila['Estado'])) ?>" style="width: <?= max(1.5, $porcentaje) ?>%"></span>
                    </span>
                    <span class="barras-valor"><?= (int) $fila['Cantidad'] ?> <small><?= moneda($fila['Monto']) ?></small></span>
                </li>
            <?php endforeach; ?>
        </ul>
        <?= fuente('sp_hes_por_estado()') ?>
    </section>

    <section class="tarjeta">
        <header class="tarjeta-cabecera">
            <h2>Últimas HES emitidas</h2>
            <a class="enlace" href="hes.php">Ver todas</a>
        </header>
        <div class="tabla-contenedor">
        <table class="tabla tabla-compacta">
            <thead>
            <tr><th>N.º HES</th><th class="ocultable">Emisión</th><th>Contratista</th><th class="derecha">Monto</th><th>Estado</th></tr>
            </thead>
            <tbody>
            <?php foreach ($recientes as $h): ?>
                <tr>
                    <td><a class="enlace codigo" href="hes_detalle.php?num=<?= e($h['Num_HES']) ?>"><?= e($h['Num_HES']) ?></a></td>
                    <td class="sin-salto ocultable"><?= fecha($h['Fecha_emision']) ?></td>
                    <td class="recortar"><?= e($h['Razon_social']) ?></td>
                    <td class="derecha"><?= moneda($h['Monto_servicio']) ?></td>
                    <td><?= insignia_estado($h['Estado']) ?></td>
                </tr>
            <?php endforeach; ?>
            </tbody>
        </table>
        </div>
        <?= fuente('sp_hes_recientes(6)') ?>
    </section>
</div>
<?php pie();
