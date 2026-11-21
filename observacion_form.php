<?php
/**
 * Corrección del comentario de una observación de una HES pendiente.
 */
require __DIR__ . '/app/inicio.php';

$numHes = parametro('hes');
$numero = parametro('num');
$observacion = null;
$error = null;
$comentario = '';

if (es_post()) {
    $comentario = valor_post('comentario');
    try {
        ObservacionDatos::actualizar($numHes, $numero, $comentario);
        avisar('correcto', "Se corrigió la observación {$numero} de la HES {$numHes}.");
        redirigir('hes_detalle.php?num=' . urlencode($numHes));
    } catch (mysqli_sql_exception $e) {
        $error = $e;
    }
}

try {
    $observacion = ObservacionDatos::obtener($numHes, $numero);
    if ($observacion && !es_post()) {
        $comentario = $observacion['Comentario'];
    }
} catch (mysqli_sql_exception $e) {
    $error = $error ?? $e;
}

encabezado('Editar observación', 'hes', 'HES ' . $numHes . ' · observación ' . $numero);
?>
<a class="volver" href="hes_detalle.php?num=<?= e(urlencode($numHes)) ?>"><?= icono('volver', 16) ?> Volver a la HES</a>

<?php if (!$observacion && !$error): ?>
    <?php mostrar_aviso('error', 'No existe esa observación.'); ?>
    <?php pie(); return; ?>
<?php endif; ?>

<?php if ($observacion && $observacion['Estado'] !== 'Pendiente'): ?>
    <?php mostrar_aviso('error', 'La HES ' . $numHes . ' está ' . strtolower($observacion['Estado']) . ': sus observaciones ya no se pueden editar.'); ?>
    <?php pie(); return; ?>
<?php endif; ?>

<?php if ($error) { error_formulario($error); } ?>

<section class="tarjeta tarjeta-formulario">
    <form class="formulario" method="post">
        <div class="resumen-lista">
            <span>HES <strong class="codigo"><?= e($numHes) ?></strong></span>
            <span>Observación <strong><?= e($numero) ?></strong></span>
            <span>Fecha: <strong><?= $observacion ? fecha($observacion['Fecha_observacion']) : '—' ?></strong></span>
        </div>
        <label class="campo">
            <span>Comentario</span>
            <textarea name="comentario" maxlength="500" required autofocus><?= e($comentario) ?></textarea>
            <small class="campo-ayuda">Hasta 500 caracteres.</small>
        </label>
        <div class="formulario-acciones">
            <button class="boton boton-primario" type="submit"><?= icono('guardar', 16) ?> Guardar</button>
            <a class="boton boton-secundario" href="hes_detalle.php?num=<?= e(urlencode($numHes)) ?>">Cancelar</a>
        </div>
    </form>
    <?= fuente('sp_observacion_actualizar(HES, número de observación, comentario)', 'Se guarda con') ?>
</section>
<?php pie();
