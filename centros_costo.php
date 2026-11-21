<?php
/**
 * Centros de costo: lista, registro, edición, baja lógica y reactivación.
 */
require __DIR__ . '/app/inicio.php';

if (es_post()) {
    $codigo = valor_post('clave');
    try {
        if (valor_post('accion') === 'baja') {
            CentroCostoDatos::eliminar($codigo);
            avisar('correcto', "El centro de costo {$codigo} fue dado de baja. Sigue registrado en la base con Activo = 0.");
        } elseif (valor_post('accion') === 'reactivar') {
            CentroCostoDatos::reactivar($codigo);
            avisar('correcto', "El centro de costo {$codigo} fue reactivado.");
        }
    } catch (mysqli_sql_exception $e) {
        avisar_error($e);
    }
    redirigir($_SERVER['REQUEST_URI']);
}

$incluirInactivos = isset($_GET['inactivos']);
$error = null;
try {
    $centros = CentroCostoDatos::listar($incluirInactivos);
} catch (mysqli_sql_exception $e) {
    $error = $e;
}

encabezado('Centros de costo', 'centros', 'Áreas de las operaciones a las que se cargan los servicios de cada contrato');

if ($error) {
    panel_error($error);
    pie();
    return;
}
?>
<section class="tarjeta">
    <form class="filtros" method="get" action="centros_costo.php">
        <label class="casilla">
            <input type="checkbox" name="inactivos" value="1" <?= $incluirInactivos ? 'checked' : '' ?> onchange="this.form.submit()">
            Incluir dados de baja
        </label>
        <span class="separador"></span>
        <a class="boton boton-primario" href="centro_costo_form.php"><?= icono('mas', 16) ?> Nuevo centro de costo</a>
    </form>

    <p class="conteo"><?= count($centros) ?> <?= count($centros) === 1 ? 'centro de costo' : 'centros de costo' ?></p>

    <div class="tabla-contenedor">
        <table class="tabla">
            <thead>
            <tr><th>Código</th><th>Nombre</th><th class="centro">Contratos vigentes</th><th>Estado</th><th class="derecha">Acciones</th></tr>
            </thead>
            <tbody>
            <?php foreach ($centros as $cc): ?>
                <?php $activo = (int) $cc['Activo'] === 1; ?>
                <tr class="<?= $activo ? '' : 'fila-inactiva' ?>">
                    <td class="codigo"><?= e($cc['Cod_centro_costo']) ?></td>
                    <td><strong><?= e($cc['Nombre_centro_costo']) ?></strong></td>
                    <td class="centro"><span class="contador"><?= (int) $cc['Contratos'] ?></span></td>
                    <td><?= insignia_activo($cc['Activo']) ?></td>
                    <td>
                        <div class="acciones-fila">
                            <?= enlace_boton('centro_costo_form.php?codigo=' . urlencode($cc['Cod_centro_costo']), 'Editar', 'editar') ?>
                            <?php if ($activo): ?>
                                <?= boton_accion('baja', $cc['Cod_centro_costo'], 'Baja', 'baja', 'boton-peligro-suave',
                                    '¿Dar de baja el centro de costo ' . $cc['Cod_centro_costo'] . '? El registro se conserva y se puede reactivar.') ?>
                            <?php else: ?>
                                <?= boton_accion('reactivar', $cc['Cod_centro_costo'], 'Reactivar', 'reactivar', 'boton-exito-suave') ?>
                            <?php endif; ?>
                        </div>
                    </td>
                </tr>
            <?php endforeach; ?>
            </tbody>
        </table>
    </div>
    <?= fuente('sp_centro_costo_listar(' . ($incluirInactivos ? 1 : 0) . ')') ?>
</section>
<?php pie();
