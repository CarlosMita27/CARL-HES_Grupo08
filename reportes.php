<?php
/**
 * Reportes de la Analista de Contratos. Cada reporte se obtiene con un procedimiento almacenado;
 * los parámetros (analista, periodo, HES o inspección) se eligen en el formulario del reporte
 * y vienen con valores de ejemplo para que el reporte se muestre al abrirlo.
 */
require __DIR__ . '/app/inicio.php';

$catalogo = ReporteDatos::CATALOGO;
$numero = (int) parametro('r', '1');
if (!isset($catalogo[$numero])) {
    $numero = 1;
}
$reporte = $catalogo[$numero];
$necesita = array_flip($reporte['parametros']);

$formatos = [
    'analista'   => '/^\d{6}$/',
    'periodo'    => '/^\d{6}$/',
    'hes'        => '/^\d{6}$/',
    'inspeccion' => '/^INS-\d{4}-\d{2}-\d{3}$/',
];
$defectos = ['analista' => '104390', 'periodo' => '202607', 'hes' => '005214', 'inspeccion' => 'INS-2026-07-007'];

$error = null;
$listas = ['analista' => [], 'periodo' => [], 'hes' => [], 'inspeccion' => []];
$valores = [];
$filas = [];
try {
    if (isset($necesita['analista'])) {
        $listas['analista'] = AnalistaDatos::listar();
    }
    if (isset($necesita['periodo'])) {
        $listas['periodo'] = SistemaDatos::periodos();
    }
    if (isset($necesita['hes'])) {
        $listas['hes'] = HesDatos::buscar('', '', '');
    }
    if (isset($necesita['inspeccion'])) {
        $listas['inspeccion'] = InspeccionDatos::buscar('', '');
    }

    foreach ($reporte['parametros'] as $nombre) {
        $valor = strtoupper(parametro($nombre, $defectos[$nombre]));
        $valores[$nombre] = preg_match($formatos[$nombre], $valor) ? $valor : '';
    }
    $completos = !in_array('', $valores, true);
    if ($completos) {
        $filas = ReporteDatos::ejecutar($numero, $valores);
    }
} catch (mysqli_sql_exception $e) {
    $error = $e;
}

encabezado('Reportes', 'reportes', 'Consultas de la Analista de Contratos obtenidas con procedimientos almacenados');

if ($error) {
    panel_error($error);
    pie();
    return;
}

$columnas = $filas ? array_keys($filas[0]) : [];
$resumen = [];
foreach (['Monto_servicio' => 'Monto', 'Monto_total' => 'Monto', 'Mora' => 'Mora', 'Mora_total' => 'Mora'] as $columna => $rotulo) {
    if (in_array($columna, $columnas, true)) {
        $resumen[] = $rotulo . ': <strong>' . moneda(array_sum(array_column($filas, $columna))) . '</strong>';
    }
}
if (in_array('Conformidad', $columnas, true)) {
    $conformes = count(array_filter($filas, function ($f) { return $f['Conformidad'] === 'Conforme'; }));
    $resumen[] = 'Conformes: <strong>' . $conformes . '</strong>';
    $resumen[] = 'Observadas: <strong>' . (count($filas) - $conformes) . '</strong>';
}
?>
<div class="rejilla-reportes">
    <aside class="tarjeta lista-reportes">
        <h2>Reportes</h2>
        <ol>
            <?php foreach ($catalogo as $n => $r): ?>
                <li class="<?= $n === $numero ? 'activo' : '' ?>">
                    <a href="reportes.php?r=<?= $n ?>">
                        <span class="numero"><?= $n ?></span>
                        <span><?= e($r['titulo']) ?></span>
                    </a>
                </li>
            <?php endforeach; ?>
        </ol>
        <p class="nota-lista">Cada reporte se obtiene con un procedimiento almacenado que combina varias tablas con JOIN.</p>
    </aside>

    <section class="tarjeta reporte">
        <header class="tarjeta-cabecera">
            <div>
                <p class="rotulo">Reporte <?= $numero ?></p>
                <h2><?= e($reporte['titulo']) ?></h2>
            </div>
            <?php if ($filas): ?>
                <button class="boton boton-secundario boton-pequeno no-imprimir" type="button" onclick="window.print()">
                    <?= icono('imprimir', 15) ?> Imprimir
                </button>
            <?php endif; ?>
        </header>
        <p class="suave"><?= e($reporte['descripcion']) ?></p>

        <?php if ($reporte['parametros']): ?>
            <form class="filtros no-imprimir" method="get" action="reportes.php">
                <input type="hidden" name="r" value="<?= $numero ?>">
                <?php if (isset($necesita['analista'])): ?>
                    <label class="campo campo-ancho">
                        <span>Analista</span>
                        <select name="analista" required>
                            <?php foreach ($listas['analista'] as $a): ?>
                                <option value="<?= e($a['Num_registro']) ?>" <?= $a['Num_registro'] === $valores['analista'] ? 'selected' : '' ?>>
                                    <?= e($a['Apellidos'] . ', ' . $a['Nombres']) ?> · <?= (int) $a['Contratos'] ?> contratos
                                </option>
                            <?php endforeach; ?>
                        </select>
                    </label>
                <?php endif; ?>
                <?php if (isset($necesita['periodo'])): ?>
                    <label class="campo">
                        <span>Periodo</span>
                        <select name="periodo" required>
                            <?php foreach ($listas['periodo'] as $p): ?>
                                <option value="<?= e($p) ?>" <?= $p === $valores['periodo'] ? 'selected' : '' ?>><?= e(periodo_texto($p)) ?></option>
                            <?php endforeach; ?>
                        </select>
                    </label>
                <?php endif; ?>
                <?php if (isset($necesita['hes'])): ?>
                    <label class="campo">
                        <span>N.º de HES</span>
                        <input name="hes" value="<?= e($valores['hes']) ?>" maxlength="6" inputmode="numeric" list="lista-hes"
                               placeholder="Por ejemplo, 005214" autocomplete="off" required>
                        <datalist id="lista-hes">
                            <?php foreach ($listas['hes'] as $h): ?>
                                <option value="<?= e($h['Num_HES']) ?>"><?= e($h['Razon_social']) ?> · <?= e($h['Estado']) ?></option>
                            <?php endforeach; ?>
                        </datalist>
                    </label>
                <?php endif; ?>
                <?php if (isset($necesita['inspeccion'])): ?>
                    <?php
                    $grupos = [];
                    foreach ($listas['inspeccion'] as $i) {
                        $grupos[$i['Periodo']][] = $i;
                    }
                    ?>
                    <label class="campo campo-ancho">
                        <span>Inspección</span>
                        <select name="inspeccion" required>
                            <?php foreach ($grupos as $periodo => $inspecciones): ?>
                                <optgroup label="<?= e(periodo_texto((string) $periodo)) ?>">
                                    <?php foreach ($inspecciones as $i): ?>
                                        <option value="<?= e($i['Num_inspeccion']) ?>" <?= $i['Num_inspeccion'] === $valores['inspeccion'] ? 'selected' : '' ?>>
                                            <?= e($i['Num_inspeccion']) ?> · HES <?= e($i['Num_HES']) ?> · <?= e($i['Razon_social']) ?>
                                        </option>
                                    <?php endforeach; ?>
                                </optgroup>
                            <?php endforeach; ?>
                        </select>
                    </label>
                <?php endif; ?>
                <button class="boton boton-primario" type="submit"><?= icono('reportes', 16) ?> Generar reporte</button>
            </form>
        <?php endif; ?>

        <?php if (!$completos): ?>
            <p class="vacio">Complete los datos del formulario para generar el reporte.</p>
        <?php elseif (!$filas): ?>
            <p class="vacio">El reporte no tiene resultados con los datos elegidos.</p>
        <?php else: ?>
            <div class="resumen-lista">
                <span><strong><?= count($filas) ?></strong> <?= count($filas) === 1 ? 'fila' : 'filas' ?></span>
                <?php foreach ($resumen as $dato): ?>
                    <span><?= $dato ?></span>
                <?php endforeach; ?>
            </div>
            <div class="tabla-contenedor">
                <table class="tabla tabla-reporte">
                    <thead>
                    <tr>
                        <?php foreach ($columnas as $columna): ?>
                            <?php [$clase] = celda_reporte($columna, '0'); ?>
                            <th class="<?= strpos($clase, 'derecha') !== false ? 'derecha' : (strpos($clase, 'centro') !== false ? 'centro' : '') ?>">
                                <?= e(titulo_columna($columna)) ?>
                            </th>
                        <?php endforeach; ?>
                    </tr>
                    </thead>
                    <tbody>
                    <?php foreach ($filas as $fila): ?>
                        <tr>
                            <?php foreach ($columnas as $columna): ?>
                                <?php [$clase, $contenido] = celda_reporte($columna, $fila[$columna]); ?>
                                <td class="<?= $clase ?>"><?= $contenido ?></td>
                            <?php endforeach; ?>
                        </tr>
                    <?php endforeach; ?>
                    </tbody>
                </table>
            </div>
        <?php endif; ?>
        <?= fuente(ReporteDatos::llamada($numero, $valores)) ?>
    </section>
</div>
<?php pie();
