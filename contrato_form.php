<?php
/**
 * Registro y edición de un contrato.
 */
require __DIR__ . '/app/inicio.php';

$numero = parametro('num');
$editar = $numero !== '';
$datos = ['num' => $numero, 'monto' => '', 'ruc' => '', 'razon_social' => '', 'centro' => '', 'analista' => ''];
$error = null;
$noEncontrado = false;

if (es_post()) {
    $datos = array_merge($datos, [
        'num'      => $editar ? $numero : valor_post('num'),
        'monto'    => valor_post('monto'),
        'ruc'      => valor_post('ruc'),
        'centro'   => valor_post('centro'),
        'analista' => valor_post('analista'),
    ]);
    try {
        if ($editar) {
            ContratoDatos::actualizar($datos['num'], nulo_si_vacio($datos['monto']), $datos['centro'], $datos['analista']);
            avisar('correcto', 'Se guardaron los cambios del contrato ' . $datos['num'] . '.');
        } else {
            ContratoDatos::insertar(strtoupper($datos['num']), nulo_si_vacio($datos['monto']), $datos['ruc'], $datos['centro'], $datos['analista']);
            avisar('correcto', 'El contrato ' . strtoupper($datos['num']) . ' fue registrado.');
        }
        redirigir('contratos.php');
    } catch (mysqli_sql_exception $e) {
        $error = $e;
    }
}

$listas = ['contratistas' => [], 'centros' => [], 'analistas' => []];
try {
    if ($editar && !es_post()) {
        $fila = ContratoDatos::obtener($numero);
        if ($fila) {
            $datos = [
                'num' => $fila['Num_contrato'], 'monto' => $fila['Monto_total'], 'ruc' => $fila['RUC'],
                'razon_social' => $fila['Razon_social'], 'centro' => $fila['Cod_centro_costo'],
                'analista' => $fila['Num_registro_analista'],
            ];
        } else {
            $noEncontrado = true;
        }
    } elseif ($editar) {
        $fila = ContratoDatos::obtener($numero);
        $datos['ruc'] = $fila['RUC'] ?? '';
        $datos['razon_social'] = $fila['Razon_social'] ?? '';
    }
    $listas['contratistas'] = ContratistaDatos::buscar('', false);
    $listas['centros'] = CentroCostoDatos::listar($editar);
    $listas['analistas'] = AnalistaDatos::listar($editar);
} catch (mysqli_sql_exception $e) {
    $error = $error ?? $e;
}

encabezado($editar ? 'Editar contrato' : 'Nuevo contrato', 'contratos',
    $editar ? 'Modifique el monto, el centro de costo o la analista' : 'Registre un contrato de servicio');
?>
<a class="volver" href="contratos.php"><?= icono('volver', 16) ?> Volver a contratos</a>

<?php if ($noEncontrado): ?>
    <?php mostrar_aviso('error', 'No existe el contrato «' . $numero . '».'); ?>
    <?php pie(); return; ?>
<?php endif; ?>

<?php if ($error) { error_formulario($error); } ?>

<section class="tarjeta tarjeta-formulario">
    <form class="formulario" method="post">
        <div class="formulario-fila">
            <label class="campo">
                <span>N.º de contrato</span>
                <input name="num" value="<?= e($datos['num']) ?>" maxlength="9" placeholder="CT-000000" autocomplete="off"
                    <?= $editar ? 'readonly' : 'required autofocus' ?>>
                <small class="campo-ayuda"><?= $editar ? 'El número no se puede cambiar.' : 'Formato CT-000000.' ?></small>
            </label>
            <label class="campo">
                <span>Monto total (S/)</span>
                <input name="monto" type="number" step="0.01" value="<?= e($datos['monto']) ?>" required>
                <small class="campo-ayuda">Mayor que cero. Use punto para los decimales.</small>
            </label>
        </div>
        <label class="campo">
            <span>Contratista</span>
            <?php if ($editar): ?>
                <input value="<?= e($datos['razon_social'] . ' · RUC ' . $datos['ruc']) ?>" readonly>
                <small class="campo-ayuda">El contrato pertenece a esta contratista y no se puede cambiar.</small>
            <?php else: ?>
                <select name="ruc" required>
                    <option value="">Seleccione una contratista</option>
                    <?php foreach ($listas['contratistas'] as $c): ?>
                        <option value="<?= e($c['RUC']) ?>" <?= $c['RUC'] === $datos['ruc'] ? 'selected' : '' ?>><?= e($c['Razon_social']) ?> · RUC <?= e($c['RUC']) ?></option>
                    <?php endforeach; ?>
                </select>
                <small class="campo-ayuda">Solo aparecen las contratistas activas.</small>
            <?php endif; ?>
        </label>
        <div class="formulario-fila">
            <label class="campo">
                <span>Centro de costo</span>
                <select name="centro" required>
                    <option value="">Seleccione un centro de costo</option>
                    <?php foreach ($listas['centros'] as $cc): ?>
                        <option value="<?= e($cc['Cod_centro_costo']) ?>" <?= $cc['Cod_centro_costo'] === $datos['centro'] ? 'selected' : '' ?>>
                            <?= e($cc['Cod_centro_costo'] . ' · ' . $cc['Nombre_centro_costo']) ?><?= (int) $cc['Activo'] === 1 ? '' : ' (dado de baja)' ?>
                        </option>
                    <?php endforeach; ?>
                </select>
            </label>
            <label class="campo">
                <span>Analista responsable</span>
                <select name="analista" required>
                    <option value="">Seleccione una analista</option>
                    <?php foreach ($listas['analistas'] as $a): ?>
                        <option value="<?= e($a['Num_registro']) ?>" <?= $a['Num_registro'] === $datos['analista'] ? 'selected' : '' ?>>
                            <?= e($a['Apellidos'] . ', ' . $a['Nombres']) ?><?= (int) $a['Activo'] === 1 ? '' : ' (dada de baja)' ?>
                        </option>
                    <?php endforeach; ?>
                </select>
            </label>
        </div>
        <div class="formulario-acciones">
            <button class="boton boton-primario" type="submit"><?= icono('guardar', 16) ?> Guardar</button>
            <a class="boton boton-secundario" href="contratos.php">Cancelar</a>
        </div>
    </form>
    <?= fuente($editar ? 'sp_contrato_actualizar(número, monto total, centro de costo, analista)'
                       : 'sp_contrato_insertar(número, monto total, RUC, centro de costo, analista)', 'Se guarda con') ?>
</section>
<?php pie();
