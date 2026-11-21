<?php
/**
 * Registro y edición de una contratista con hasta tres teléfonos.
 */
require __DIR__ . '/app/inicio.php';

$ruc = parametro('ruc');
$editar = $ruc !== '';
$datos = ['ruc' => $ruc, 'razon_social' => '', 'telefonos' => ['', '', '']];
$error = null;
$noEncontrada = false;

if (es_post()) {
    $datos = [
        'ruc'          => $editar ? $ruc : valor_post('ruc'),
        'razon_social' => valor_post('razon_social'),
        'telefonos'    => [valor_post('telefono1'), valor_post('telefono2'), valor_post('telefono3')],
    ];
    try {
        if ($editar) {
            ContratistaDatos::actualizar($datos['ruc'], $datos['razon_social'], $datos['telefonos']);
            avisar('correcto', 'Se guardaron los cambios de la contratista con RUC ' . $datos['ruc'] . '.');
        } else {
            ContratistaDatos::insertar($datos['ruc'], $datos['razon_social'], $datos['telefonos']);
            avisar('correcto', 'La contratista ' . $datos['razon_social'] . ' fue registrada.');
        }
        redirigir('contratistas.php');
    } catch (mysqli_sql_exception $e) {
        $error = $e;
    }
} elseif ($editar) {
    try {
        $fila = ContratistaDatos::obtener($ruc);
        if ($fila) {
            $datos = [
                'ruc'          => $fila['RUC'],
                'razon_social' => $fila['Razon_social'],
                'telefonos'    => array_pad($fila['Telefonos'], 3, ''),
            ];
        } else {
            $noEncontrada = true;
        }
    } catch (mysqli_sql_exception $e) {
        $error = $e;
    }
}

encabezado($editar ? 'Editar contratista' : 'Nueva contratista', 'contratistas',
    $editar ? 'Modifique los datos y guarde los cambios' : 'Registre una empresa contratista con sus teléfonos');
?>
<a class="volver" href="contratistas.php"><?= icono('volver', 16) ?> Volver a contratistas</a>

<?php if ($noEncontrada): ?>
    <?php mostrar_aviso('error', 'No existe una contratista con el RUC «' . $ruc . '».'); ?>
    <?php pie(); return; ?>
<?php endif; ?>

<?php if ($error) { error_formulario($error); } ?>

<section class="tarjeta tarjeta-formulario">
    <form class="formulario" method="post">
        <div class="formulario-fila">
            <label class="campo">
                <span>RUC</span>
                <input name="ruc" value="<?= e($datos['ruc']) ?>" maxlength="11" inputmode="numeric" autocomplete="off"
                    <?= $editar ? 'readonly' : 'required autofocus' ?>>
                <small class="campo-ayuda"><?= $editar ? 'El RUC identifica a la contratista y no se puede cambiar.' : '11 dígitos.' ?></small>
            </label>
            <label class="campo">
                <span>Razón social</span>
                <input name="razon_social" value="<?= e($datos['razon_social']) ?>" maxlength="100" required>
                <small class="campo-ayuda">Hasta 100 caracteres.</small>
            </label>
        </div>
        <fieldset class="grupo-campos">
            <legend>Teléfonos</legend>
            <div class="formulario-fila tres">
                <?php foreach ([1, 2, 3] as $n): ?>
                    <label class="campo">
                        <span>Teléfono <?= $n ?></span>
                        <input name="telefono<?= $n ?>" value="<?= e($datos['telefonos'][$n - 1]) ?>" maxlength="9" inputmode="numeric" autocomplete="off">
                    </label>
                <?php endforeach; ?>
            </div>
            <small class="campo-ayuda">9 dígitos cada uno. Los campos vacíos no se guardan.</small>
        </fieldset>
        <div class="formulario-acciones">
            <button class="boton boton-primario" type="submit"><?= icono('guardar', 16) ?> Guardar</button>
            <a class="boton boton-secundario" href="contratistas.php">Cancelar</a>
        </div>
    </form>
    <?= fuente($editar ? 'sp_contratista_actualizar(ruc, razón social, teléfono 1, teléfono 2, teléfono 3)'
                       : 'sp_contratista_insertar(ruc, razón social, teléfono 1, teléfono 2, teléfono 3)', 'Se guarda con') ?>
</section>
<?php pie();
