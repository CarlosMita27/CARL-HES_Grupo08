<?php
/**
 * Detalle de una HES: datos de la hoja, contrato, contratista, analista, inspección y observaciones.
 * Si la HES está pendiente, desde aquí se edita, se aprueba, se rechaza, se retira, se anula
 * y se registran observaciones.
 */
require __DIR__ . '/app/inicio.php';

$numHes = parametro('num');
$valido = (bool) preg_match('/^\d{6}$/', $numHes);

if (es_post() && $valido) {
    $mensajes = [
        'aprobar'  => ['Aprobada', "La HES {$numHes} fue aprobada y queda liberada para facturación."],
        'rechazar' => ['Rechazada', "La HES {$numHes} fue rechazada."],
        'retirar'  => ['Retirada', "La HES {$numHes} fue retirada."],
    ];
    $accion = valor_post('accion');
    try {
        if (isset($mensajes[$accion])) {
            HesDatos::cambiarEstado($numHes, $mensajes[$accion][0]);
            avisar('correcto', $mensajes[$accion][1]);
        } elseif ($accion === 'anular') {
            HesDatos::anular($numHes);
            avisar('correcto', "La HES {$numHes} fue anulada. Se conserva en la base con el estado Anulada.");
        } elseif ($accion === 'observar') {
            $numero = ObservacionDatos::registrar($numHes, nulo_si_vacio(valor_post('fecha')), valor_post('comentario'));
            avisar('correcto', "Se registró la observación {$numero} de la HES {$numHes}.");
        }
    } catch (mysqli_sql_exception $e) {
        avisar_error($e);
        if ($accion === 'observar') {
            $_SESSION['borrador_observacion'] = ['fecha' => valor_post('fecha'), 'comentario' => valor_post('comentario')];
        }
    }
    redirigir('hes_detalle.php?num=' . urlencode($numHes));
}

$error = null;
$hes = null;
$observaciones = [];
try {
    if ($valido) {
        $hes = HesDatos::detalle($numHes);
        $observaciones = $hes ? HesDatos::observaciones($numHes) : [];
    }
} catch (mysqli_sql_exception $e) {
    $error = $e;
}

$borrador = $_SESSION['borrador_observacion'] ?? ['fecha' => date('Y-m-d'), 'comentario' => ''];
unset($_SESSION['borrador_observacion']);

encabezado($hes ? 'HES ' . $hes['Num_HES'] : 'Detalle de HES', 'hes', $hes ? $hes['Razon_social'] : 'Hoja de Entrada de Servicio');

if ($error) {
    panel_error($error);
    pie();
    return;
}
?>
<a class="volver" href="hes.php"><?= icono('volver', 16) ?> Volver a la lista de HES</a>

<?php if (!$hes): ?>
    <section class="aviso aviso-error">
        <?= icono('error', 22) ?>
        <div>
            <h2>HES no encontrada</h2>
            <p>No existe una HES con el número «<?= e($numHes) ?>». El número tiene seis dígitos, por ejemplo 005214.</p>
        </div>
    </section>
    <?php pie(); return; ?>
<?php endif; ?>

<?php $pendiente = $hes['Estado'] === 'Pendiente'; ?>

<section class="cabecera-hes tarjeta">
    <div>
        <p class="rotulo">Hoja de Entrada de Servicio</p>
        <h2 class="numero-hes"><?= e($hes['Num_HES']) ?> <?= insignia_estado($hes['Estado']) ?></h2>
        <p class="suave">Emitida el <?= fecha($hes['Fecha_emision']) ?> · Periodo <?= e(periodo_texto($hes['Periodo'])) ?></p>
    </div>
    <div class="cabecera-montos">
        <div>
            <p class="rotulo">Monto del servicio</p>
            <p class="monto-grande"><?= moneda($hes['Monto_servicio']) ?></p>
        </div>
        <?php if ($hes['Dias_en_espera'] !== null): ?>
            <div>
                <p class="rotulo">Días en espera</p>
                <p class="monto-grande tono-texto-ambar"><?= (int) $hes['Dias_en_espera'] ?></p>
            </div>
        <?php endif; ?>
    </div>
</section>

<section class="tarjeta barra-acciones-hes">
    <?php if ($pendiente): ?>
        <p class="nota">La HES está pendiente de revisión. Acciones disponibles:</p>
        <div class="barra-acciones">
            <?= enlace_boton('hes_form.php?num=' . urlencode($hes['Num_HES']), 'Editar', 'editar') ?>
            <?= boton_accion('aprobar', $hes['Num_HES'], 'Aprobar', 'aprobada', 'boton-exito',
                '¿Aprobar la HES ' . $hes['Num_HES'] . '? Quedará liberada para facturación y ya no se podrá modificar.') ?>
            <?= boton_accion('rechazar', $hes['Num_HES'], 'Rechazar', 'baja', 'boton-peligro-suave',
                '¿Rechazar la HES ' . $hes['Num_HES'] . '?') ?>
            <?= boton_accion('retirar', $hes['Num_HES'], 'Retirar', 'retirar', 'boton-secundario',
                '¿Retirar la HES ' . $hes['Num_HES'] . '?') ?>
            <?= boton_accion('anular', $hes['Num_HES'], 'Anular', 'anular', 'boton-peligro',
                '¿Anular la HES ' . $hes['Num_HES'] . '? Se conservará en la base con el estado Anulada.') ?>
        </div>
    <?php else: ?>
        <p class="nota">La HES está <?= e(strtolower($hes['Estado'])) ?>: ya no admite cambios ni observaciones nuevas.</p>
    <?php endif; ?>
</section>

<div class="rejilla-tres">
    <section class="tarjeta ficha">
        <h3><?= icono('contratos', 18) ?> Contrato</h3>
        <dl>
            <dt>Número</dt><dd class="codigo"><?= e($hes['Num_contrato']) ?></dd>
            <dt>Monto total</dt><dd><?= moneda($hes['Monto_total']) ?></dd>
            <dt>Centro de costo</dt><dd><?= e($hes['Cod_centro_costo']) ?> · <?= e($hes['Nombre_centro_costo']) ?></dd>
        </dl>
    </section>
    <section class="tarjeta ficha">
        <h3><?= icono('contratistas', 18) ?> Contratista</h3>
        <dl>
            <dt>Razón social</dt><dd><?= e($hes['Razon_social']) ?></dd>
            <dt>RUC</dt><dd class="codigo"><?= e($hes['RUC']) ?></dd>
            <dt>Teléfonos</dt><dd><?= e($hes['Telefonos'] ?? '—') ?></dd>
        </dl>
    </section>
    <section class="tarjeta ficha">
        <h3><?= icono('analistas', 18) ?> Analista responsable</h3>
        <dl>
            <dt>Nombre</dt><dd><?= e($hes['Analista']) ?></dd>
            <dt>Cargo</dt><dd><?= e($hes['Cargo']) ?></dd>
            <dt>N.º de registro</dt><dd class="codigo"><?= e($hes['Num_registro']) ?></dd>
        </dl>
    </section>
</div>

<section class="tarjeta">
    <header class="tarjeta-cabecera">
        <h2><?= icono('inspecciones', 18) ?> Inspección de obligaciones laborales</h2>
        <span class="tarjeta-nota codigo"><?= e($hes['Num_inspeccion']) ?></span>
    </header>
    <div class="cifras">
        <div><p class="rotulo">Firma de la contratista</p><p class="<?= $hes['Firma_contratista'] === 'Firmado' ? '' : 'tono-texto-rojo' ?>"><?= e($hes['Firma_contratista']) ?></p></div>
        <div><p class="rotulo">Reportes de entidades</p><p><?= (int) $hes['Reportes'] ?></p></div>
        <div><p class="rotulo">Boletas de pago</p><p><?= (int) $hes['Boletas'] ?></p></div>
        <div><p class="rotulo">Boletas sin firma</p><p class="<?= (int) $hes['Boletas_sin_firma'] > 0 ? 'tono-texto-rojo' : '' ?>"><?= (int) $hes['Boletas_sin_firma'] ?></p></div>
        <div><p class="rotulo">Declaraciones juradas</p><p><?= (int) $hes['Declaraciones'] ?></p></div>
    </div>
    <?= fuente("sp_hes_detalle('" . $hes['Num_HES'] . "')") ?>
</section>

<section class="tarjeta">
    <header class="tarjeta-cabecera">
        <h2><?= icono('observaciones', 18) ?> Observaciones</h2>
        <span class="tarjeta-nota"><?= count($observaciones) ?> registradas</span>
    </header>
    <?php if (!$observaciones): ?>
        <p class="vacio">Esta HES no tiene observaciones.</p>
    <?php else: ?>
        <ol class="linea-tiempo">
            <?php foreach ($observaciones as $o): ?>
                <li>
                    <span class="linea-numero"><?= (int) $o['Num_observacion'] ?></span>
                    <div>
                        <p class="rotulo"><?= fecha($o['Fecha_observacion']) ?></p>
                        <p><?= e($o['Comentario']) ?></p>
                    </div>
                    <?php if ($pendiente): ?>
                        <span class="linea-accion">
                            <?= enlace_boton('observacion_form.php?hes=' . urlencode($hes['Num_HES']) . '&num=' . (int) $o['Num_observacion'], 'Editar', 'editar') ?>
                        </span>
                    <?php endif; ?>
                </li>
            <?php endforeach; ?>
        </ol>
    <?php endif; ?>

    <?php if ($pendiente): ?>
        <form class="formulario formulario-observacion" method="post">
            <input type="hidden" name="accion" value="observar">
            <h3>Registrar observación</h3>
            <div class="formulario-fila fila-observacion">
                <label class="campo">
                    <span>Fecha</span>
                    <input name="fecha" type="date" value="<?= e($borrador['fecha']) ?>" required>
                </label>
                <label class="campo">
                    <span>Comentario</span>
                    <textarea name="comentario" maxlength="500" required placeholder="Describa el documento faltante o la diferencia encontrada"><?= e($borrador['comentario']) ?></textarea>
                </label>
            </div>
            <div class="formulario-acciones">
                <button class="boton boton-primario" type="submit"><?= icono('mas', 16) ?> Registrar observación</button>
            </div>
        </form>
    <?php endif; ?>
    <?= fuente("sp_hes_observaciones('" . $hes['Num_HES'] . "')" . ($pendiente ? ' · sp_observacion_registrar(HES, fecha, comentario)' : '')) ?>
</section>
<?php pie();
