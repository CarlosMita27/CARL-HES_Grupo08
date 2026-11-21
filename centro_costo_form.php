<?php
/**
 * Registro y edición de un centro de costo.
 */
require __DIR__ . '/app/inicio.php';

$codigo = parametro('codigo');
$editar = $codigo !== '';
$datos = ['codigo' => $codigo, 'nombre' => ''];
$error = null;
$noEncontrado = false;

if (es_post()) {
    $datos = ['codigo' => $editar ? $codigo : valor_post('codigo'), 'nombre' => valor_post('nombre')];
    try {
        if ($editar) {
            CentroCostoDatos::actualizar($datos['codigo'], $datos['nombre']);
            avisar('correcto', 'Se guardaron los cambios del centro de costo ' . $datos['codigo'] . '.');
        } else {
            CentroCostoDatos::insertar($datos['codigo'], $datos['nombre']);
            avisar('correcto', 'El centro de costo ' . strtoupper($datos['codigo']) . ' fue registrado.');
        }
        redirigir('centros_costo.php');
    } catch (mysqli_sql_exception $e) {
        $error = $e;
    }
} elseif ($editar) {
    try {
        $fila = CentroCostoDatos::obtener($codigo);
        if ($fila) {
            $datos = ['codigo' => $fila['Cod_centro_costo'], 'nombre' => $fila['Nombre_centro_costo']];
        } else {
            $noEncontrado = true;
        }
    } catch (mysqli_sql_exception $e) {
        $error = $e;
    }
}

encabezado($editar ? 'Editar centro de costo' : 'Nuevo centro de costo', 'centros',
    $editar ? 'Modifique el nombre y guarde los cambios' : 'Registre un centro de costo');
?>
<a class="volver" href="centros_costo.php"><?= icono('volver', 16) ?> Volver a centros de costo</a>

<?php if ($noEncontrado): ?>
    <?php mostrar_aviso('error', 'No existe el centro de costo «' . $codigo . '».'); ?>
    <?php pie(); return; ?>
<?php endif; ?>

<?php if ($error) { error_formulario($error); } ?>

<section class="tarjeta tarjeta-formulario">
    <form class="formulario" method="post">
        <div class="formulario-fila">
            <label class="campo">
                <span>Código</span>
                <input name="codigo" value="<?= e($datos['codigo']) ?>" maxlength="10" autocomplete="off"
                    <?= $editar ? 'readonly' : 'required autofocus' ?>>
                <small class="campo-ayuda"><?= $editar ? 'El código no se puede cambiar.' : 'Letras y números, hasta 10 caracteres (por ejemplo, TQMIN02).' ?></small>
            </label>
            <label class="campo">
                <span>Nombre</span>
                <input name="nombre" value="<?= e($datos['nombre']) ?>" maxlength="80" required>
                <small class="campo-ayuda">Hasta 80 caracteres; no se puede repetir.</small>
            </label>
        </div>
        <div class="formulario-acciones">
            <button class="boton boton-primario" type="submit"><?= icono('guardar', 16) ?> Guardar</button>
            <a class="boton boton-secundario" href="centros_costo.php">Cancelar</a>
        </div>
    </form>
    <?= fuente($editar ? 'sp_centro_costo_actualizar(código, nombre)' : 'sp_centro_costo_insertar(código, nombre)', 'Se guarda con') ?>
</section>
<?php pie();
