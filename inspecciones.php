<?php
/**
 * Inspecciones de obligaciones laborales: consulta por número, HES o contratista, con filtro de periodo.
 * Cada inspección se crea junto con su HES; desde aquí se abre su HES y su reporte de conformidad.
 */
require __DIR__ . '/app/inicio.php';

$texto = parametro('q');
$periodo = parametro('periodo');
if (!preg_match('/^\d{6}$/', $periodo)) {
    $periodo = '';
}

$error = null;
try {
    $periodos = SistemaDatos::periodos();
    $inspecciones = InspeccionDatos::buscar($texto, $periodo);
} catch (mysqli_sql_exception $e) {
    $error = $e;
}

encabezado('Inspecciones', 'inspecciones', 'Inspecciones de obligaciones laborales y documentación que presentó cada contratista');

if ($error) {
    panel_error($error);
    pie();
    return;
}
?>
<section class="tarjeta">
    <form class="filtros" method="get" action="inspecciones.php">
        <label class="campo campo-busqueda">
            <?= icono('buscar') ?>
            <input type="search" name="q" value="<?= e($texto) ?>" placeholder="N.º de inspección, HES o contratista" autocomplete="off">
        </label>
        <label class="campo">
            <span>Periodo</span>
            <select name="periodo">
                <option value="">Todos</option>
                <?php foreach ($periodos as $p): ?>
                    <option value="<?= e($p) ?>" <?= $p === $periodo ? 'selected' : '' ?>><?= e(periodo_texto($p)) ?></option>
                <?php endforeach; ?>
            </select>
        </label>
        <button class="boton boton-primario" type="submit"><?= icono('buscar', 16) ?> Filtrar</button>
        <a class="boton boton-secundario" href="inspecciones.php">Limpiar</a>
    </form>
    <p class="nota">Cada inspección se registra junto con su HES. Haga clic en el número de la inspección para ver la conformidad
        de sus obligaciones, o en el número de la HES para abrir su detalle.</p>

    <p class="conteo">
        <?= count($inspecciones) ?> <?= count($inspecciones) === 1 ? 'inspección encontrada' : 'inspecciones encontradas' ?>
        <?php if ($periodo !== ''): ?> en <?= e(periodo_texto($periodo)) ?><?php endif; ?>
    </p>

    <?php if (!$inspecciones): ?>
        <p class="vacio">No hay inspecciones que coincidan con la búsqueda.</p>
    <?php else: ?>
        <div class="tabla-contenedor">
            <table class="tabla tabla-densa">
                <thead>
                <tr>
                    <th>Inspección</th><th>HES</th><th>Contratista</th><th>Firma</th>
                    <th class="centro">Reportes</th><th class="centro">Boletas</th><th class="centro">Sin firma</th>
                    <th class="centro">DJ</th>
                </tr>
                </thead>
                <tbody>
                <?php foreach ($inspecciones as $i): ?>
                    <tr>
                        <td class="sin-salto">
                            <a class="enlace codigo" href="reportes.php?r=7&amp;inspeccion=<?= e(urlencode($i['Num_inspeccion'])) ?>"
                               title="Ver la conformidad de las obligaciones"><?= e($i['Num_inspeccion']) ?></a>
                        </td>
                        <td class="sin-salto">
                            <a class="enlace codigo" href="hes_detalle.php?num=<?= e($i['Num_HES']) ?>"><?= e($i['Num_HES']) ?></a>
                            <?= insignia_estado($i['Estado']) ?>
                        </td>
                        <td class="recortar recortar-corto" title="<?= e($i['Razon_social']) ?>"><?= e($i['Razon_social']) ?></td>
                        <td class="sin-salto <?= $i['Firma_contratista'] === 'Firmado' ? '' : 'tono-texto-rojo' ?>"><?= e($i['Firma_contratista']) ?></td>
                        <td class="centro"><span class="contador <?= (int) $i['Reportes'] === 0 ? 'contador-rojo' : '' ?>"><?= (int) $i['Reportes'] ?></span></td>
                        <td class="centro"><span class="contador <?= (int) $i['Boletas'] === 0 ? 'contador-rojo' : '' ?>"><?= (int) $i['Boletas'] ?></span></td>
                        <td class="centro"><span class="contador <?= (int) $i['Boletas_sin_firma'] > 0 ? 'contador-rojo' : '' ?>"><?= (int) $i['Boletas_sin_firma'] ?></span></td>
                        <td class="centro"><span class="contador"><?= (int) $i['Declaraciones'] ?></span></td>
                    </tr>
                <?php endforeach; ?>
                </tbody>
            </table>
        </div>
    <?php endif; ?>
    <?= fuente("sp_inspeccion_buscar('" . $texto . "', '" . $periodo . "')") ?>
</section>
<?php pie();
