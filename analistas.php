<?php
/**
 * Analistas de contratos: lista, registro, edición, baja lógica y reactivación.
 */
require __DIR__ . '/app/inicio.php';

if (es_post()) {
    $registro = valor_post('clave');
    try {
        if (valor_post('accion') === 'baja') {
            AnalistaDatos::eliminar($registro);
            avisar('correcto', "La analista con registro {$registro} fue dada de baja. Sigue registrada en la base con Activo = 0.");
        } elseif (valor_post('accion') === 'reactivar') {
            AnalistaDatos::reactivar($registro);
            avisar('correcto', "La analista con registro {$registro} fue reactivada.");
        }
    } catch (mysqli_sql_exception $e) {
        avisar_error($e);
    }
    redirigir($_SERVER['REQUEST_URI']);
}

$incluirInactivos = isset($_GET['inactivos']);
$error = null;
try {
    $analistas = AnalistaDatos::listar($incluirInactivos);
} catch (mysqli_sql_exception $e) {
    $error = $e;
}

encabezado('Analistas', 'analistas', 'Analistas de contratos responsables de revisar y liberar las HES');

if ($error) {
    panel_error($error);
    pie();
    return;
}
?>
<section class="tarjeta">
    <form class="filtros" method="get" action="analistas.php">
        <label class="casilla">
            <input type="checkbox" name="inactivos" value="1" <?= $incluirInactivos ? 'checked' : '' ?> onchange="this.form.submit()">
            Incluir dadas de baja
        </label>
        <span class="separador"></span>
        <a class="boton boton-primario" href="analista_form.php"><?= icono('mas', 16) ?> Nueva analista</a>
    </form>

    <p class="conteo"><?= count($analistas) ?> <?= count($analistas) === 1 ? 'analista' : 'analistas' ?></p>

    <div class="tabla-contenedor">
        <table class="tabla">
            <thead>
            <tr><th>N.º de registro</th><th>Apellidos y nombres</th><th>Cargo</th><th class="centro">Contratos vigentes</th><th>Estado</th><th class="derecha">Acciones</th></tr>
            </thead>
            <tbody>
            <?php foreach ($analistas as $a): ?>
                <?php $activo = (int) $a['Activo'] === 1; ?>
                <tr class="<?= $activo ? '' : 'fila-inactiva' ?>">
                    <td class="codigo"><?= e($a['Num_registro']) ?></td>
                    <td><strong><?= e($a['Apellidos']) ?></strong>, <?= e($a['Nombres']) ?></td>
                    <td><?= e($a['Cargo']) ?></td>
                    <td class="centro"><span class="contador"><?= (int) $a['Contratos'] ?></span></td>
                    <td><?= insignia_activo($a['Activo']) ?></td>
                    <td>
                        <div class="acciones-fila">
                            <?= enlace_boton('analista_form.php?registro=' . urlencode($a['Num_registro']), 'Editar', 'editar') ?>
                            <?php if ($activo): ?>
                                <?= boton_accion('baja', $a['Num_registro'], 'Baja', 'baja', 'boton-peligro-suave',
                                    '¿Dar de baja a ' . $a['Nombres'] . ' ' . $a['Apellidos'] . '? El registro se conserva y se puede reactivar.') ?>
                            <?php else: ?>
                                <?= boton_accion('reactivar', $a['Num_registro'], 'Reactivar', 'reactivar', 'boton-exito-suave') ?>
                            <?php endif; ?>
                        </div>
                    </td>
                </tr>
            <?php endforeach; ?>
            </tbody>
        </table>
    </div>
    <?= fuente('sp_analista_listar(' . ($incluirInactivos ? 1 : 0) . ')') ?>
</section>
<?php pie();
