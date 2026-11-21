<?php
/**
 * Registro y edición de una analista de contratos.
 */
require __DIR__ . '/app/inicio.php';

$registro = parametro('registro');
$editar = $registro !== '';
$datos = ['registro' => $registro, 'apellidos' => '', 'nombres' => '', 'cargo' => ''];
$error = null;
$noEncontrada = false;

if (es_post()) {
    $datos = [
        'registro'  => $editar ? $registro : valor_post('registro'),
        'apellidos' => valor_post('apellidos'),
        'nombres'   => valor_post('nombres'),
        'cargo'     => valor_post('cargo'),
    ];
    try {
        if ($editar) {
            AnalistaDatos::actualizar($datos['registro'], $datos['apellidos'], $datos['nombres'], $datos['cargo']);
            avisar('correcto', 'Se guardaron los cambios de ' . $datos['nombres'] . ' ' . $datos['apellidos'] . '.');
        } else {
            AnalistaDatos::insertar($datos['registro'], $datos['apellidos'], $datos['nombres'], $datos['cargo']);
            avisar('correcto', 'La analista ' . $datos['nombres'] . ' ' . $datos['apellidos'] . ' fue registrada.');
        }
        redirigir('analistas.php');
    } catch (mysqli_sql_exception $e) {
        $error = $e;
    }
}

$cargos = [];
try {
    if ($editar && !es_post()) {
        $fila = AnalistaDatos::obtener($registro);
        if ($fila) {
            $datos = ['registro' => $fila['Num_registro'], 'apellidos' => $fila['Apellidos'],
                      'nombres' => $fila['Nombres'], 'cargo' => (string) $fila['Cod_cargo']];
        } else {
            $noEncontrada = true;
        }
    }
    $cargos = AnalistaDatos::cargos();
} catch (mysqli_sql_exception $e) {
    $error = $error ?? $e;
}

encabezado($editar ? 'Editar analista' : 'Nueva analista', 'analistas',
    $editar ? 'Modifique los datos y guarde los cambios' : 'Registre una analista de contratos');
?>
<a class="volver" href="analistas.php"><?= icono('volver', 16) ?> Volver a analistas</a>

<?php if ($noEncontrada): ?>
    <?php mostrar_aviso('error', 'No existe una analista con el registro «' . $registro . '».'); ?>
    <?php pie(); return; ?>
<?php endif; ?>

<?php if ($error) { error_formulario($error); } ?>

<section class="tarjeta tarjeta-formulario">
    <form class="formulario" method="post">
        <div class="formulario-fila">
            <label class="campo">
                <span>N.º de registro</span>
                <input name="registro" value="<?= e($datos['registro']) ?>" maxlength="6" inputmode="numeric" autocomplete="off"
                    <?= $editar ? 'readonly' : 'required autofocus' ?>>
                <small class="campo-ayuda"><?= $editar ? 'El número de registro no se puede cambiar.' : '6 dígitos.' ?></small>
            </label>
            <label class="campo">
                <span>Cargo</span>
                <select name="cargo" required>
                    <option value="">Seleccione un cargo</option>
                    <?php foreach ($cargos as $c): ?>
                        <option value="<?= (int) $c['Cod_cargo'] ?>" <?= (string) $c['Cod_cargo'] === $datos['cargo'] ? 'selected' : '' ?>><?= e($c['Nombre_cargo']) ?></option>
                    <?php endforeach; ?>
                </select>
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
            <a class="boton boton-secundario" href="analistas.php">Cancelar</a>
        </div>
    </form>
    <?= fuente($editar ? 'sp_analista_actualizar(registro, apellidos, nombres, cargo)'
                       : 'sp_analista_insertar(registro, apellidos, nombres, cargo)', 'Se guarda con') ?>
</section>
<?php pie();
