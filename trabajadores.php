<?php
/**
 * Trabajadores de las contratistas: búsqueda, registro, edición, baja lógica y reactivación.
 */
require __DIR__ . '/app/inicio.php';

if (es_post()) {
    $dni = valor_post('clave');
    try {
        if (valor_post('accion') === 'baja') {
            TrabajadorDatos::eliminar($dni);
            avisar('correcto', "El trabajador con DNI {$dni} fue dado de baja. Sigue registrado en la base con Activo = 0.");
        } elseif (valor_post('accion') === 'reactivar') {
            TrabajadorDatos::reactivar($dni);
            avisar('correcto', "El trabajador con DNI {$dni} fue reactivado.");
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
    $trabajadores = TrabajadorDatos::buscar($texto, $incluirInactivos);
} catch (mysqli_sql_exception $e) {
    $error = $e;
}

encabezado('Trabajadores', 'trabajadores', 'Personal de las contratistas cuyas boletas de pago se revisan en cada inspección');

if ($error) {
    panel_error($error);
    pie();
    return;
}
?>
<section class="tarjeta">
    <form class="filtros" method="get" action="trabajadores.php">
        <label class="campo campo-busqueda">
            <?= icono('buscar') ?>
            <input type="search" name="q" value="<?= e($texto) ?>" placeholder="Buscar por DNI, apellidos, nombres o contratista" autocomplete="off">
        </label>
        <label class="casilla">
            <input type="checkbox" name="inactivos" value="1" <?= $incluirInactivos ? 'checked' : '' ?>>
            Incluir dados de baja
        </label>
        <button class="boton boton-primario" type="submit"><?= icono('buscar', 16) ?> Buscar</button>
        <a class="boton boton-secundario" href="trabajadores.php">Limpiar</a>
        <span class="separador"></span>
        <a class="boton boton-primario" href="trabajador_form.php"><?= icono('mas', 16) ?> Nuevo trabajador</a>
    </form>

    <p class="conteo">
        <?= count($trabajadores) ?> <?= count($trabajadores) === 1 ? 'trabajador encontrado' : 'trabajadores encontrados' ?>
        <?php if ($texto !== ''): ?> para «<?= e($texto) ?>»<?php endif; ?>
    </p>

    <?php if (!$trabajadores): ?>
        <p class="vacio">No hay trabajadores que coincidan con la búsqueda.</p>
    <?php else: ?>
        <div class="tabla-contenedor">
            <table class="tabla">
                <thead>
                <tr>
                    <th>DNI</th><th>Apellidos y nombres</th><th>Contratista</th>
                    <th class="centro">Boletas</th><th>Estado</th><th class="derecha">Acciones</th>
                </tr>
                </thead>
                <tbody>
                <?php foreach ($trabajadores as $t): ?>
                    <?php $activo = (int) $t['Activo'] === 1; ?>
                    <tr class="<?= $activo ? '' : 'fila-inactiva' ?>">
                        <td class="codigo"><?= e($t['DNI']) ?></td>
                        <td><strong><?= e($t['Apellidos']) ?></strong>, <?= e($t['Nombres']) ?></td>
                        <td class="recortar"><?= e($t['Razon_social']) ?></td>
                        <td class="centro"><span class="contador"><?= (int) $t['Boletas'] ?></span></td>
                        <td><?= insignia_activo($t['Activo']) ?></td>
                        <td>
                            <div class="acciones-fila">
                                <?= enlace_boton('trabajador_form.php?dni=' . urlencode($t['DNI']), 'Editar', 'editar') ?>
                                <?php if ($activo): ?>
                                    <?= boton_accion('baja', $t['DNI'], 'Baja', 'baja', 'boton-peligro-suave',
                                        '¿Dar de baja a ' . $t['Nombres'] . ' ' . $t['Apellidos'] . '? El registro se conserva y se puede reactivar.') ?>
                                <?php else: ?>
                                    <?= boton_accion('reactivar', $t['DNI'], 'Reactivar', 'reactivar', 'boton-exito-suave') ?>
                                <?php endif; ?>
                            </div>
                        </td>
                    </tr>
                <?php endforeach; ?>
                </tbody>
            </table>
        </div>
    <?php endif; ?>
    <?= fuente("sp_trabajador_buscar('" . $texto . "', " . ($incluirInactivos ? 1 : 0) . ')') ?>
</section>
<?php pie();
