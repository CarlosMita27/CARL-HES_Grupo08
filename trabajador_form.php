<?php
/**
 * Registro y edición de un trabajador de una contratista.
 */
require __DIR__ . '/app/inicio.php';

$dni = parametro('dni');
$editar = $dni !== '';
$datos = ['dni' => $dni, 'apellidos' => '', 'nombres' => '', 'ruc' => '', 'razon_social' => ''];
$error = null;
$noEncontrado = false;

if (es_post()) {
    $datos = array_merge($datos, [
        'dni'       => $editar ? $dni : valor_post('dni'),
        'apellidos' => valor_post('apellidos'),
        'nombres'   => valor_post('nombres'),
        'ruc'       => valor_post('ruc'),
    ]);
    try {
        if ($editar) {
            TrabajadorDatos::actualizar($datos['dni'], $datos['apellidos'], $datos['nombres']);
            avisar('correcto', 'Se guardaron los cambios de ' . $datos['nombres'] . ' ' . $datos['apellidos'] . '.');
        } else {
            TrabajadorDatos::insertar($datos['dni'], $datos['apellidos'], $datos['nombres'], $datos['ruc']);
            avisar('correcto', 'El trabajador ' . $datos['nombres'] . ' ' . $datos['apellidos'] . ' fue registrado.');
        }
        redirigir('trabajadores.php');
    } catch (mysqli_sql_exception $e) {
        $error = $e;
    }
}

$contratistas = [];
try {
    if ($editar) {
        $fila = TrabajadorDatos::obtener($dni);
        if ($fila && !es_post()) {
            $datos = ['dni' => $fila['DNI'], 'apellidos' => $fila['Apellidos'], 'nombres' => $fila['Nombres'],
                      'ruc' => $fila['RUC'], 'razon_social' => $fila['Razon_social']];
        } elseif ($fila) {
            $datos['ruc'] = $fila['RUC'];
            $datos['razon_social'] = $fila['Razon_social'];
        } else {
            $noEncontrado = true;
        }
    } else {
        $contratistas = ContratistaDatos::buscar('', false);
    }
} catch (mysqli_sql_exception $e) {
    $error = $error ?? $e;
}

encabezado($editar ? 'Editar trabajador' : 'Nuevo trabajador', 'trabajadores',
    $editar ? 'Modifique los datos y guarde los cambios' : 'Registre a un trabajador de una contratista');
?>
<a class="volver" href="trabajadores.php"><?= icono('volver', 16) ?> Volver a trabajadores</a>

<?php if ($noEncontrado): ?>
    <?php mostrar_aviso('error', 'No existe un trabajador con el DNI «' . $dni . '».'); ?>
    <?php pie(); return; ?>
<?php endif; ?>

<?php if ($error) { error_formulario($error); } ?>

<section class="tarjeta tarjeta-formulario">
    <form class="formulario" method="post">
        <div class="formulario-fila">
            <label class="campo">
                <span>DNI</span>
                <input name="dni" value="<?= e($datos['dni']) ?>" maxlength="8" inputmode="numeric" autocomplete="off"
                    <?= $editar ? 'readonly' : 'required autofocus' ?>>
                <small class="campo-ayuda"><?= $editar ? 'El DNI no se puede cambiar.' : '8 dígitos.' ?></small>
            </label>
            <label class="campo">
                <span>Contratista</span>
                <?php if ($editar): ?>
                    <input value="<?= e($datos['razon_social']) ?> · RUC <?= e($datos['ruc']) ?>" readonly>
                    <small class="campo-ayuda">El trabajador no cambia de contratista: sus boletas pertenecen a ella.</small>
                <?php else: ?>
                    <select name="ruc" required>
                        <option value="">Seleccione una contratista</option>
                        <?php foreach ($contratistas as $c): ?>
                            <option value="<?= e($c['RUC']) ?>" <?= $c['RUC'] === $datos['ruc'] ? 'selected' : '' ?>><?= e($c['Razon_social']) ?></option>
                        <?php endforeach; ?>
                    </select>
                    <small class="campo-ayuda">Solo se muestran las contratistas vigentes.</small>
                <?php endif; ?>
            </label>
        </div>
        <div class="formulario-fila">
            <label class="campo">
                <span>Apellidos</span>
                <input name="apellidos" value="<?= e($datos['apellidos']) ?>" maxlength="50" required>
            </label>
            <label class="campo">
                <span>Nombres</span>
                <input name="nombres" value="<?= e($datos['nombres']) ?>" maxlength="50" required>
            </label>
        </div>
        <div class="formulario-acciones">
            <button class="boton boton-primario" type="submit"><?= icono('guardar', 16) ?> Guardar</button>
            <a class="boton boton-secundario" href="trabajadores.php">Cancelar</a>
        </div>
    </form>
    <?= fuente($editar ? 'sp_trabajador_actualizar(dni, apellidos, nombres)'
                       : 'sp_trabajador_insertar(dni, apellidos, nombres, ruc)', 'Se guarda con') ?>
</section>
<?php pie();
