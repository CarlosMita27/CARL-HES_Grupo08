<?php
/**
 * Registro de una HES pendiente (con su inspección de obligaciones) y corrección de una HES pendiente.
 */
require __DIR__ . '/app/inicio.php';

$numHes = parametro('num');
$editar = $numHes !== '';
$datos = [
    'num' => '', 'fecha' => date('Y-m-d'), 'monto' => '', 'contrato' => '',
    'periodo' => date('Y-m', strtotime('first day of last month')), 'firma' => 'Firmado',
];
$hes = null;
$error = null;

if (es_post()) {
    $datos = array_merge($datos, [
        'num'      => $editar ? $numHes : valor_post('num'),
        'fecha'    => valor_post('fecha'),
        'monto'    => valor_post('monto'),
        'contrato' => valor_post('contrato'),
        'periodo'  => valor_post('periodo'),
        'firma'    => valor_post('firma'),
    ]);
    try {
        if ($editar) {
            HesDatos::actualizar($numHes, nulo_si_vacio($datos['fecha']), nulo_si_vacio($datos['monto']));
            avisar('correcto', "Se guardaron los cambios de la HES {$numHes}.");
            redirigir('hes_detalle.php?num=' . urlencode($numHes));
        } else {
            $periodo = str_replace('-', '', $datos['periodo']);
            $inspeccion = HesDatos::registrar($datos['num'], nulo_si_vacio($datos['fecha']), nulo_si_vacio($datos['monto']),
                $datos['contrato'], $periodo, $datos['firma']);
            avisar('correcto', "La HES {$datos['num']} fue registrada como pendiente, con la inspección {$inspeccion}.");
            redirigir('hes_detalle.php?num=' . urlencode($datos['num']));
        }
    } catch (mysqli_sql_exception $e) {
        $error = $e;
    }
}

$contratos = [];
try {
    if ($editar) {
        $hes = HesDatos::detalle($numHes);
        if ($hes && !es_post()) {
            $datos['fecha'] = $hes['Fecha_emision'];
            $datos['monto'] = $hes['Monto_servicio'];
        }
    } else {
        $contratos = ContratoDatos::buscar('', false);
        if (!es_post()) {
            $datos['num'] = HesDatos::siguienteNumero();
        }
    }
} catch (mysqli_sql_exception $e) {
    $error = $error ?? $e;
}

encabezado($editar ? 'Editar HES ' . $numHes : 'Registrar HES', 'hes',
    $editar ? 'Corrija la fecha de emisión o el monto de una HES pendiente' : 'Registre una HES pendiente con su inspección de obligaciones');
?>
<a class="volver" href="<?= $editar ? 'hes_detalle.php?num=' . e(urlencode($numHes)) : 'hes.php' ?>"><?= icono('volver', 16) ?> Volver</a>

<?php if ($editar && !$hes && !$error): ?>
    <?php mostrar_aviso('error', 'No existe una HES con el número «' . $numHes . '».'); ?>
    <?php pie(); return; ?>
<?php endif; ?>

<?php if ($editar && $hes && $hes['Estado'] !== 'Pendiente'): ?>
    <?php mostrar_aviso('error', 'La HES ' . $numHes . ' está ' . strtolower($hes['Estado']) . ': solo se puede editar una HES pendiente.'); ?>
    <?php pie(); return; ?>
<?php endif; ?>

<?php if ($error) { error_formulario($error); } ?>

<section class="tarjeta tarjeta-formulario">
    <form class="formulario" method="post">
        <?php if ($editar): ?>
            <div class="resumen-lista">
                <span>Contrato <strong class="codigo"><?= e($hes['Num_contrato']) ?></strong></span>
                <span><?= e($hes['Razon_social']) ?></span>
                <span>Inspección <strong class="codigo"><?= e($hes['Num_inspeccion']) ?></strong> · <?= e(periodo_texto($hes['Periodo'])) ?></span>
            </div>
        <?php endif; ?>
        <div class="formulario-fila tres">
            <label class="campo">
                <span>N.º de HES</span>
                <input name="num" value="<?= e($editar ? $numHes : $datos['num']) ?>" maxlength="6" inputmode="numeric" autocomplete="off"
                    <?= $editar ? 'readonly' : 'required' ?>>
                <small class="campo-ayuda"><?= $editar ? 'El número no se puede cambiar.' : '6 dígitos. Se sugiere el siguiente número.' ?></small>
            </label>
            <label class="campo">
                <span>Fecha de emisión</span>
                <input name="fecha" type="date" value="<?= e($datos['fecha']) ?>" required>
                <small class="campo-ayuda">No puede ser posterior a hoy.</small>
            </label>
            <label class="campo">
                <span>Monto del servicio (S/)</span>
                <input name="monto" type="number" step="0.01" value="<?= e($datos['monto']) ?>" required <?= $editar ? 'autofocus' : '' ?>>
                <small class="campo-ayuda">Mayor que cero.</small>
            </label>
        </div>
        <?php if (!$editar): ?>
            <label class="campo">
                <span>Contrato</span>
                <select name="contrato" required>
                    <option value="">Seleccione un contrato vigente</option>
                    <?php foreach ($contratos as $c): ?>
                        <option value="<?= e($c['Num_contrato']) ?>" <?= $c['Num_contrato'] === $datos['contrato'] ? 'selected' : '' ?>>
                            <?= e($c['Num_contrato'] . ' · ' . $c['Razon_social']) ?>
                        </option>
                    <?php endforeach; ?>
                </select>
            </label>
            <fieldset class="grupo-campos">
                <legend>Inspección de obligaciones laborales</legend>
                <div class="formulario-fila">
                    <label class="campo">
                        <span>Periodo</span>
                        <input name="periodo" type="month" value="<?= e($datos['periodo']) ?>" required>
                        <small class="campo-ayuda">Mes de las obligaciones que se revisan.</small>
                    </label>
                    <label class="campo">
                        <span>Firma de la contratista en el formato</span>
                        <select name="firma" required>
                            <?php foreach (['Firmado', 'No firmado'] as $f): ?>
                                <option value="<?= e($f) ?>" <?= $f === $datos['firma'] ? 'selected' : '' ?>><?= e($f) ?></option>
                            <?php endforeach; ?>
                        </select>
                    </label>
                </div>
                <small class="campo-ayuda">El número de inspección se genera solo: INS-aaaa-mm-nnn.</small>
            </fieldset>
        <?php endif; ?>
        <div class="formulario-acciones">
            <button class="boton boton-primario" type="submit"><?= icono('guardar', 16) ?> Guardar</button>
            <a class="boton boton-secundario" href="<?= $editar ? 'hes_detalle.php?num=' . e(urlencode($numHes)) : 'hes.php' ?>">Cancelar</a>
        </div>
    </form>
    <?= fuente($editar ? 'sp_hes_actualizar(número, fecha de emisión, monto)'
                       : 'sp_hes_registrar(número, fecha de emisión, monto, contrato, periodo, firma)', 'Se guarda con') ?>
</section>
<?php pie();
