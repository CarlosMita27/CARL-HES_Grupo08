<?php
/**
 * HES: búsqueda por número, contrato, RUC o razón social, con filtros de estado y periodo.
 * Desde aquí se registra una HES nueva.
 */
require __DIR__ . '/app/inicio.php';

$texto = parametro('q');
$estado = parametro('estado');
$periodo = parametro('periodo');
if (!in_array($estado, HesDatos::ESTADOS, true)) {
    $estado = '';
}
if (!preg_match('/^\d{6}$/', $periodo)) {
    $periodo = '';
}

$error = null;
try {
    $periodos = SistemaDatos::periodos();
    $lista = HesDatos::buscar($texto, $estado, $periodo);
} catch (mysqli_sql_exception $e) {
    $error = $e;
}

encabezado('HES', 'hes', 'Hojas de Entrada de Servicio emitidas por los usuarios del área');

if ($error) {
    panel_error($error);
    pie();
    return;
}

$montoTotal = array_sum(array_column($lista, 'Monto_servicio'));
?>
<section class="tarjeta">
    <form class="filtros" method="get" action="hes.php">
        <label class="campo campo-busqueda">
            <?= icono('buscar') ?>
            <input type="search" name="q" value="<?= e($texto) ?>" placeholder="N.º de HES, contrato, RUC o razón social" autocomplete="off">
        </label>
        <label class="campo">
            <span>Estado</span>
            <select name="estado">
                <option value="">Todos</option>
                <?php foreach (HesDatos::ESTADOS as $opcion): ?>
                    <option value="<?= e($opcion) ?>" <?= $opcion === $estado ? 'selected' : '' ?>><?= e($opcion) ?></option>
                <?php endforeach; ?>
            </select>
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
        <a class="boton boton-secundario" href="hes.php">Limpiar</a>
        <span class="separador"></span>
        <a class="boton boton-primario" href="hes_form.php"><?= icono('mas', 16) ?> Registrar HES</a>
    </form>

    <div class="resumen-lista">
        <span><strong><?= count($lista) ?></strong> HES</span>
        <span>Monto total: <strong><?= moneda($montoTotal) ?></strong></span>
    </div>

    <?php if (!$lista): ?>
        <p class="vacio">No hay HES que coincidan con los filtros.</p>
    <?php else: ?>
        <div class="tabla-contenedor">
            <table class="tabla">
                <thead>
                <tr>
                    <th>N.º HES</th><th>Emisión</th><th class="ocultable">Periodo</th><th>Contratista</th>
                    <th>Contrato</th><th>Analista</th><th class="derecha">Monto</th><th>Estado</th>
                </tr>
                </thead>
                <tbody>
                <?php foreach ($lista as $h): ?>
                    <tr>
                        <td><a class="enlace codigo" href="hes_detalle.php?num=<?= e($h['Num_HES']) ?>"><?= e($h['Num_HES']) ?></a></td>
                        <td class="sin-salto"><?= fecha($h['Fecha_emision']) ?></td>
                        <td class="suave sin-salto ocultable"><?= e(periodo_corto($h['Periodo'])) ?></td>
                        <td class="recortar"><?= e($h['Razon_social']) ?></td>
                        <td class="codigo"><?= e($h['Num_contrato']) ?></td>
                        <td class="sin-salto"><?= e($h['Analista']) ?></td>
                        <td class="derecha"><?= moneda($h['Monto_servicio']) ?></td>
                        <td><?= insignia_estado($h['Estado']) ?></td>
                    </tr>
                <?php endforeach; ?>
                </tbody>
            </table>
        </div>
    <?php endif; ?>
    <?= fuente("sp_hes_buscar('" . $texto . "', '" . $estado . "', '" . $periodo . "')") ?>
</section>
<?php pie();
