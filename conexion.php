<?php
/**
 * Prueba de conexión con la base de datos hes_spcc.
 *  - Prueba la conexión configurada en config/config.php al abrir la página.
 *  - Permite probar con otros datos (por ejemplo, una contraseña incorrecta).
 *  - Comprueba que el usuario del aplicativo no pueda leer las tablas directamente.
 */
require __DIR__ . '/app/inicio.php';

/** Abre una conexión, mide el tiempo y consulta sp_info_conexion. */
function probar_conexion(string $servidor, int $puerto, string $base, string $usuario, string $clave): array
{
    $resultado = ['conectado' => false, 'ms' => 0.0, 'info' => null, 'error' => null];
    $inicio = microtime(true);
    try {
        $cn = Conexion::abrir($servidor, $puerto, $base, $usuario, $clave);
        $resultado['ms'] = (microtime(true) - $inicio) * 1000;
        $resultado['conectado'] = true;
        $resultado['info'] = SistemaDatos::infoConexion($cn);
        $cn->close();
    } catch (mysqli_sql_exception $e) {
        if (!$resultado['conectado']) {
            $resultado['ms'] = (microtime(true) - $inicio) * 1000;
        }
        $resultado['error'] = $e;
    }
    return $resultado;
}

/** Intenta leer la tabla HES sin procedimiento, con el usuario del aplicativo. */
function probar_permisos(): array
{
    $sql = 'SELECT COUNT(*) FROM HES';
    try {
        $filas = Conexion::obtener()->query($sql)->fetch_row();
        return ['sql' => $sql, 'protegido' => false, 'detalle' => 'La consulta devolvió ' . $filas[0] . ' filas.'];
    } catch (mysqli_sql_exception $e) {
        return ['sql' => $sql, 'protegido' => $e->getCode() === 1142,
                'detalle' => 'Error ' . $e->getCode() . ': ' . $e->getMessage()];
    }
}

/** Muestra el resultado de una prueba de conexión. */
function mostrar_resultado(array $r): void
{
    if ($r['conectado'] && $r['info']): ?>
        <div class="resultado resultado-correcto">
            <?= icono('correcto', 22) ?>
            <div>
                <strong>Conexión establecida</strong>
                <span>en <?= number_format($r['ms'], 1) ?> ms con MySQL <?= e($r['info']['Version_servidor']) ?></span>
            </div>
        </div>
    <?php elseif ($r['conectado']): ?>
        <div class="resultado resultado-error">
            <?= icono('error', 22) ?>
            <div>
                <strong>Conexión establecida, pero no se pudo ejecutar sp_info_conexion</strong>
                <span><?= e(explicar_error($r['error'])) ?></span>
                <code>Error <?= (int) $r['error']->getCode() ?>: <?= e($r['error']->getMessage()) ?></code>
            </div>
        </div>
    <?php else: ?>
        <div class="resultado resultado-error">
            <?= icono('error', 22) ?>
            <div>
                <strong>No se pudo conectar</strong>
                <span><?= e(explicar_error($r['error'])) ?></span>
                <code>Error <?= (int) $r['error']->getCode() ?>: <?= e($r['error']->getMessage()) ?></code>
            </div>
        </div>
    <?php endif;
}

$config = Conexion::configuracion();
$principal = probar_conexion($config['servidor'], (int) $config['puerto'], $config['base'], $config['usuario'], $config['clave']);

$accion = $_POST['accion'] ?? '';
$otra = null;
$permiso = null;
$formulario = [
    'servidor' => $config['servidor'],
    'puerto'   => (string) $config['puerto'],
    'base'     => $config['base'],
    'usuario'  => $config['usuario'],
];
if ($accion === 'otra') {
    foreach (array_keys($formulario) as $campo) {
        $formulario[$campo] = trim((string) ($_POST[$campo] ?? ''));
    }
    $otra = probar_conexion($formulario['servidor'], (int) $formulario['puerto'], $formulario['base'],
        $formulario['usuario'], (string) ($_POST['clave'] ?? ''));
} elseif ($accion === 'permisos' && $principal['conectado']) {
    $permiso = probar_permisos();
}

encabezado('Prueba de conexión', 'conexion', 'Comunicación nativa del aplicativo con MySQL mediante mysqli, sin frameworks');
$info = $principal['info'];
?>
<section class="tarjeta">
    <header class="tarjeta-cabecera">
        <h2><?= icono('conexion', 18) ?> Conexión del aplicativo</h2>
        <a class="boton boton-secundario" href="conexion.php">Probar de nuevo</a>
    </header>
    <?php mostrar_resultado($principal); ?>

    <div class="rejilla-dos rejilla-datos">
        <dl class="datos">
            <dt>Servidor</dt><dd class="codigo"><?= e($config['servidor']) ?>:<?= (int) $config['puerto'] ?></dd>
            <dt>Base de datos</dt><dd class="codigo"><?= e($config['base']) ?></dd>
            <dt>Usuario</dt><dd class="codigo"><?= e($config['usuario']) ?></dd>
            <dt>Contraseña</dt><dd>•••••••••• <span class="suave">(config/config.php)</span></dd>
            <dt>Conector</dt><dd>mysqli · <?= e(mysqli_get_client_info()) ?></dd>
            <dt>PHP</dt><dd><?= e(PHP_VERSION) ?></dd>
        </dl>
        <dl class="datos">
            <dt>Versión de MySQL</dt><dd><?= $info ? e($info['Version_servidor']) : '—' ?></dd>
            <dt>Base en uso</dt><dd class="codigo"><?= $info ? e($info['Base_datos']) : '—' ?></dd>
            <dt>Usuario conectado</dt><dd class="codigo"><?= $info ? e($info['Usuario_conectado']) : '—' ?></dd>
            <dt>Fecha y hora del servidor</dt><dd><?= $info ? e(fecha_hora($info['Fecha_hora_servidor'])) : '—' ?></dd>
            <dt>Objetos de la base</dt>
            <dd><?= $info ? (int) $info['Tablas'] . ' tablas · ' . (int) $info['Procedimientos'] . ' procedimientos · ' . (int) $info['Triggers'] . ' triggers' : '—' ?></dd>
        </dl>
    </div>
    <?= fuente('sp_info_conexion()') ?>
</section>

<div class="rejilla-dos">
    <section class="tarjeta">
        <header class="tarjeta-cabecera">
            <h2>Probar con otros datos</h2>
        </header>
        <p class="suave">Los datos se usan solo para esta prueba; no cambian la configuración del aplicativo.</p>
        <form class="formulario" method="post" action="conexion.php">
            <input type="hidden" name="accion" value="otra">
            <div class="formulario-fila">
                <label class="campo"><span>Servidor</span><input name="servidor" value="<?= e($formulario['servidor']) ?>" required></label>
                <label class="campo campo-corto"><span>Puerto</span><input name="puerto" value="<?= e($formulario['puerto']) ?>" inputmode="numeric" required></label>
            </div>
            <div class="formulario-fila">
                <label class="campo"><span>Base de datos</span><input name="base" value="<?= e($formulario['base']) ?>" required></label>
                <label class="campo"><span>Usuario</span><input name="usuario" value="<?= e($formulario['usuario']) ?>" required></label>
            </div>
            <label class="campo"><span>Contraseña</span><input type="password" name="clave" autocomplete="off"></label>
            <button class="boton boton-primario" type="submit"><?= icono('conexion', 16) ?> Probar conexión</button>
        </form>
        <?php if ($otra) { mostrar_resultado($otra); } ?>
    </section>

    <section class="tarjeta">
        <header class="tarjeta-cabecera">
            <h2><?= icono('escudo', 18) ?> Permisos del usuario del aplicativo</h2>
        </header>
        <p class="suave">El usuario <code><?= e($config['usuario']) ?></code> solo tiene permiso para ejecutar procedimientos.
            Esta prueba intenta leer la tabla HES directamente, sin procedimiento; MySQL debe rechazarla.</p>
        <form class="acciones" method="post" action="conexion.php">
            <input type="hidden" name="accion" value="permisos">
            <button class="boton boton-secundario" type="submit" <?= $principal['conectado'] ? '' : 'disabled' ?>>
                Intentar leer la tabla HES directamente
            </button>
        </form>
        <?php if ($permiso): ?>
            <div class="resultado <?= $permiso['protegido'] ? 'resultado-correcto' : 'resultado-alerta' ?>">
                <?= icono($permiso['protegido'] ? 'escudo' : 'error', 22) ?>
                <div>
                    <strong><?= $permiso['protegido'] ? 'Acceso directo rechazado, como se esperaba' : 'El usuario puede leer la tabla directamente' ?></strong>
                    <span><?= $permiso['protegido']
                            ? 'El aplicativo solo puede trabajar con la base a través de procedimientos almacenados.'
                            : 'Para el aplicativo se recomienda el usuario app_hes, que solo ejecuta procedimientos.' ?></span>
                    <code><?= e($permiso['sql']) ?> → <?= e($permiso['detalle']) ?></code>
                </div>
            </div>
        <?php endif; ?>
    </section>
</div>
<?php pie();
