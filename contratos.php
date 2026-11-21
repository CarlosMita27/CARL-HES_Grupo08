<?php
/**
 * Contratos: búsqueda, registro, edición, baja lógica y reactivación.
 */
require __DIR__ . '/app/inicio.php';

if (es_post()) {
    $numero = valor_post('clave');
    try {
        if (valor_post('accion') === 'baja') {
            ContratoDatos::eliminar($numero);
            avisar('correcto', "El contrato {$numero} fue dado de baja. Sigue registrado en la base con Activo = 0.");
        } elseif (valor_post('accion') === 'reactivar') {
            ContratoDatos::reactivar($numero);
            avisar('correcto', "El contrato {$numero} fue reactivado.");
        }
    } catch (mysqli_sql_exception $e) {
        avisar_error($e);
    }
    redirigir($_SERVER['REQUEST_URI']);
}

$texto = parametro('q');
$incluirInactivos = isset($_GET['inactivos']);

$error = null;
try {
    $contratos = ContratoDatos::buscar($texto, $incluirInactivos);
} catch (mysqli_sql_exception $e) {
    $error = $e;
}

encabezado('Contratos', 'contratos', 'Contratos de servicio con su contratista, centro de costo y analista responsable');

if ($error) {
    panel_error($error);
    pie();
    return;
}
?>
<section class="tarjeta">
    <form class="filtros" method="get" action="contratos.php">
        <label class="campo campo-busqueda">
            <?= icono('buscar') ?>
            <input type="search" name="q" value="<?= e($texto) ?>" placeholder="N.º de contrato, RUC o razón social" autocomplete="off">
        </label>
        <label class="casilla">
            <input type="checkbox" name="inactivos" value="1" <?= $incluirInactivos ? 'checked' : '' ?>>
            Incluir dados de baja
        </label>
        <button class="boton boton-primario" type="submit"><?= icono('buscar', 16) ?> Buscar</button>
        <a class="boton boton-secundario" href="contratos.php">Limpiar</a>
        <span class="separador"></span>
        <a class="boton boton-primario" href="contrato_form.php"><?= icono('mas', 16) ?> Nuevo contrato</a>
    </form>

    <p class="conteo"><?= count($contratos) ?> <?= count($contratos) === 1 ? 'contrato encontrado' : 'contratos encontrados' ?></p>

    <?php if (!$contratos): ?>
        <p class="vacio">No hay contratos que coincidan con la búsqueda.</p>
    <?php else: ?>
        <div class="tabla-contenedor">
            <table class="tabla tabla-densa">
                <thead>
                <tr>
                    <th>Contrato</th><th>Contratista</th><th class="ocultable-amplio">Centro de costo</th><th>Analista</th>
                    <th>Monto total y aprobado</th><th class="centro ocultable">HES pend.</th>
                    <th>Estado</th><th class="derecha">Acciones</th>
                </tr>
                </thead>
                <tbody>
                <?php foreach ($contratos as $c): ?>
                    <?php
                    $activo = (int) $c['Activo'] === 1;
                    $avance = (float) $c['Monto_total'] > 0 ? min(100, $c['Monto_aprobado'] * 100 / $c['Monto_total']) : 0;
                    ?>
                    <tr class="<?= $activo ? '' : 'fila-inactiva' ?>">
                        <td class="codigo"><?= e($c['Num_contrato']) ?></td>
                        <td class="recortar recortar-mini"><?= e($c['Razon_social']) ?></td>
                        <td class="ocultable-amplio"><span class="codigo"><?= e($c['Cod_centro_costo']) ?></span></td>
                        <td class="sin-salto"><?= e($c['Analista']) ?></td>
                        <td>
                            <div class="monto-ejecucion" title="<?= moneda($c['Monto_aprobado']) ?> aprobado en HES">
                                <span><?= moneda($c['Monto_total']) ?></span>
                                <div class="ejecucion">
                                    <span class="barras-pista"><span class="barras-relleno relleno-aprobada" style="width: <?= max(1, round($avance, 1)) ?>%"></span></span>
                                    <small><?= number_format($avance, 1) ?> %</small>
                                </div>
                            </div>
                        </td>
                        <td class="centro ocultable">
                            <?php if ((int) $c['Hes_pendientes'] > 0): ?>
                                <a class="contador contador-ambar" href="hes.php?q=<?= e($c['Num_contrato']) ?>&amp;estado=Pendiente"><?= (int) $c['Hes_pendientes'] ?></a>
                            <?php else: ?>
                                <span class="contador">0</span>
                            <?php endif; ?>
                        </td>
                        <td><?= insignia_activo($c['Activo']) ?></td>
                        <td>
                            <div class="acciones-fila">
                                <?= enlace_boton('contrato_form.php?num=' . urlencode($c['Num_contrato']), 'Editar', 'editar') ?>
                                <?php if ($activo): ?>
                                    <?= boton_accion('baja', $c['Num_contrato'], 'Baja', 'baja', 'boton-peligro-suave',
                                        '¿Dar de baja el contrato ' . $c['Num_contrato'] . '? El registro se conserva y se puede reactivar.') ?>
                                <?php else: ?>
                                    <?= boton_accion('reactivar', $c['Num_contrato'], 'Reactivar', 'reactivar', 'boton-exito-suave') ?>
                                <?php endif; ?>
                            </div>
                        </td>
                    </tr>
                <?php endforeach; ?>
                </tbody>
            </table>
        </div>
    <?php endif; ?>
    <?= fuente("sp_contrato_buscar('" . $texto . "', " . ($incluirInactivos ? 1 : 0) . ')') ?>
</section>
<?php pie();
