<?php
/**
 * Contratistas: búsqueda, registro, edición, baja lógica y reactivación.
 */
require __DIR__ . '/app/inicio.php';

if (es_post()) {
    $ruc = valor_post('clave');
    try {
        if (valor_post('accion') === 'baja') {
            ContratistaDatos::eliminar($ruc);
            avisar('correcto', "La contratista con RUC {$ruc} fue dada de baja. Sigue registrada en la base con Activo = 0.");
        } elseif (valor_post('accion') === 'reactivar') {
            ContratistaDatos::reactivar($ruc);
            avisar('correcto', "La contratista con RUC {$ruc} fue reactivada.");
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
    $contratistas = ContratistaDatos::buscar($texto, $incluirInactivos);
} catch (mysqli_sql_exception $e) {
    $error = $e;
}

encabezado('Contratistas', 'contratistas', 'Empresas que prestan servicios a la empresa y presentan su documentación laboral');

if ($error) {
    panel_error($error);
    pie();
    return;
}
?>
<section class="tarjeta">
    <form class="filtros" method="get" action="contratistas.php">
        <label class="campo campo-busqueda">
            <?= icono('buscar') ?>
            <input type="search" name="q" value="<?= e($texto) ?>" placeholder="Buscar por RUC o razón social" autocomplete="off">
        </label>
        <label class="casilla">
            <input type="checkbox" name="inactivos" value="1" <?= $incluirInactivos ? 'checked' : '' ?>>
            Incluir dadas de baja
        </label>
        <button class="boton boton-primario" type="submit"><?= icono('buscar', 16) ?> Buscar</button>
        <a class="boton boton-secundario" href="contratistas.php">Limpiar</a>
        <span class="separador"></span>
        <a class="boton boton-primario" href="contratista_form.php"><?= icono('mas', 16) ?> Nueva contratista</a>
    </form>

    <p class="conteo">
        <?= count($contratistas) ?> <?= count($contratistas) === 1 ? 'contratista encontrada' : 'contratistas encontradas' ?>
        <?php if ($texto !== ''): ?> para «<?= e($texto) ?>»<?php endif; ?>
    </p>

    <?php if (!$contratistas): ?>
        <p class="vacio">No hay contratistas que coincidan con la búsqueda.</p>
    <?php else: ?>
        <div class="tabla-contenedor">
            <table class="tabla">
                <thead>
                <tr>
                    <th>RUC</th><th>Razón social</th><th class="ocultable">Teléfonos</th>
                    <th class="centro">Contratos</th><th class="centro">HES pend.</th><th>Estado</th><th class="derecha">Acciones</th>
                </tr>
                </thead>
                <tbody>
                <?php foreach ($contratistas as $c): ?>
                    <?php $activo = (int) $c['Activo'] === 1; ?>
                    <tr class="<?= $activo ? '' : 'fila-inactiva' ?>">
                        <td class="codigo"><?= e($c['RUC']) ?></td>
                        <td><strong><?= e($c['Razon_social']) ?></strong></td>
                        <td class="suave ocultable"><?= $c['Telefonos'] !== '' ? e($c['Telefonos']) : '—' ?></td>
                        <td class="centro"><?= (int) $c['Contratos'] ?></td>
                        <td class="centro">
                            <?php if ((int) $c['Hes_pendientes'] > 0): ?>
                                <a class="contador contador-ambar" href="hes.php?q=<?= e($c['RUC']) ?>&amp;estado=Pendiente"><?= (int) $c['Hes_pendientes'] ?></a>
                            <?php else: ?>
                                <span class="contador">0</span>
                            <?php endif; ?>
                        </td>
                        <td><?= insignia_activo($c['Activo']) ?></td>
                        <td>
                            <div class="acciones-fila">
                                <?= enlace_boton('contratista_form.php?ruc=' . urlencode($c['RUC']), 'Editar', 'editar') ?>
                                <?php if ($activo): ?>
                                    <?= boton_accion('baja', $c['RUC'], 'Baja', 'baja', 'boton-peligro-suave',
                                        '¿Dar de baja a ' . $c['Razon_social'] . '? El registro se conserva y se puede reactivar.') ?>
                                <?php else: ?>
                                    <?= boton_accion('reactivar', $c['RUC'], 'Reactivar', 'reactivar', 'boton-exito-suave') ?>
                                <?php endif; ?>
                            </div>
                        </td>
                    </tr>
                <?php endforeach; ?>
                </tbody>
            </table>
        </div>
    <?php endif; ?>
    <?= fuente("sp_contratista_buscar('" . $texto . "', " . ($incluirInactivos ? 1 : 0) . ')') ?>
</section>
<?php pie();
