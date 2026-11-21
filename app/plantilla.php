<?php
/**
 * Estructura común de las páginas: menú lateral, barra superior y pie.
 */

/** Opciones del menú: clave, texto y página. */
function opciones_menu(): array
{
    return [
        'General' => [
            ['inicio', 'Inicio', 'index.php'],
            ['conexion', 'Prueba de conexión', 'conexion.php'],
        ],
        'Gestión' => [
            ['contratistas', 'Contratistas', 'contratistas.php'],
            ['contratos', 'Contratos', 'contratos.php'],
            ['analistas', 'Analistas', 'analistas.php'],
            ['centros', 'Centros de costo', 'centros_costo.php'],
            ['hes', 'HES', 'hes.php'],
            ['inspecciones', 'Inspecciones', 'inspecciones.php'],
            ['trabajadores', 'Trabajadores', 'trabajadores.php'],
        ],
        'Consultas' => [
            ['reportes', 'Reportes', 'reportes.php'],
        ],
    ];
}

/** Imprime el inicio de la página hasta el contenido principal. */
function encabezado(string $titulo, string $activo, string $subtitulo = ''): void
{
    $conectado = Conexion::disponible();
    $config = Conexion::configuracion();
    $version = '';
    if ($conectado && preg_match('/^\d+\.\d+\.\d+/', Conexion::obtener()->server_info, $m)) {
        $version = $m[0];
    }
    ?>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title><?= e($titulo) ?> · CARL-HES</title>
    <link rel="icon" href="assets/img/icono.svg" type="image/svg+xml">
    <link rel="stylesheet" href="assets/css/estilos.css">
</head>
<body>
<div class="aplicacion">
    <aside class="lateral">
        <a class="marca" href="index.php">
            <img src="assets/img/icono.svg" alt="" width="38" height="38">
            <span>
                <strong>CARL-HES</strong>
                <small>Revisión y liberación de HES</small>
            </span>
        </a>
        <nav class="menu">
            <?php foreach (opciones_menu() as $grupo => $opciones): ?>
                <p class="menu-grupo"><?= e($grupo) ?></p>
                <?php foreach ($opciones as [$clave, $texto, $pagina]): ?>
                    <a class="menu-opcion<?= $clave === $activo ? ' activa' : '' ?>" href="<?= e($pagina) ?>">
                        <?= icono($clave) ?><span><?= e($texto) ?></span>
                    </a>
                <?php endforeach; ?>
            <?php endforeach; ?>
        </nav>
        <div class="lateral-pie">
            <span>CARL-HES · Versión 1.0</span>
            <small>Control y Aprobación de la Revisión y Liberación de HES</small>
            <small>Grupo 08 · GDI · UCSM 2026</small>
        </div>
    </aside>

    <div class="principal">
        <header class="barra-superior">
            <div>
                <h1><?= e($titulo) ?></h1>
                <?php if ($subtitulo !== ''): ?><p><?= e($subtitulo) ?></p><?php endif; ?>
            </div>
            <a class="estado-conexion <?= $conectado ? 'en-linea' : 'sin-conexion' ?>" href="conexion.php"
               title="Ir a la prueba de conexión">
                <span class="punto"></span>
                <?php if ($conectado): ?>
                    Conectado a <?= e($config['base']) ?> · MySQL <?= e($version) ?>
                <?php else: ?>
                    Sin conexión con la base de datos
                <?php endif; ?>
            </a>
        </header>
        <main class="contenido">
    <?php
    $aviso = tomar_aviso();
    if ($aviso) {
        mostrar_aviso($aviso['tipo'], $aviso['texto'], $aviso['detalle']);
    }
}

/** Muestra un aviso de operación correcta o de error. */
function mostrar_aviso(string $tipo, string $texto, string $detalle = ''): void
{
    ?>
    <section class="aviso aviso-<?= $tipo === 'correcto' ? 'correcto' : 'error' ?>" role="status">
        <?= icono($tipo === 'correcto' ? 'correcto' : 'error', 22) ?>
        <div>
            <p class="aviso-texto"><?= e($texto) ?></p>
            <?php if ($detalle !== ''): ?><p class="aviso-detalle"><?= e($detalle) ?></p><?php endif; ?>
        </div>
    </section>
    <?php
}

/** Muestra en un formulario el error que devolvió MySQL. */
function error_formulario(mysqli_sql_exception $e): void
{
    mostrar_aviso('error', mensaje_error($e), 'Error ' . $e->getCode() . ' de MySQL: ' . $e->getMessage());
}

/** Imprime el cierre de la página. */
function pie(): void
{
    ?>
        </main>
        <footer class="pie">
            Proyecto académico · Gestión de Datos e Información · Universidad Católica de Santa María · 2026 · Datos ficticios
        </footer>
    </div>
</div>
</body>
</html>
    <?php
}

/** Muestra un error de MySQL con su código, su mensaje y una explicación. */
function panel_error(mysqli_sql_exception $e): void
{
    ?>
    <section class="aviso aviso-error">
        <?= icono('error', 22) ?>
        <div>
            <h2>No se pudo completar la operación</h2>
            <p><?= e(explicar_error($e)) ?></p>
            <p class="aviso-detalle">Error <?= (int) $e->getCode() ?> de MySQL: <?= e($e->getMessage()) ?></p>
            <a class="boton boton-secundario" href="conexion.php">Ir a la prueba de conexión</a>
        </div>
    </section>
    <?php
}

/** Botón que envía una acción por POST (dar de baja, reactivar, aprobar…), con confirmación opcional. */
function boton_accion(string $accion, string $clave, string $texto, string $icono, string $clase, string $confirmacion = ''): string
{
    $confirmar = $confirmacion !== ''
        ? ' onsubmit="return confirm(' . e(json_encode($confirmacion, JSON_UNESCAPED_UNICODE)) . ')"'
        : '';
    return '<form method="post" class="en-linea"' . $confirmar . '>'
        . '<input type="hidden" name="accion" value="' . e($accion) . '">'
        . '<input type="hidden" name="clave" value="' . e($clave) . '">'
        . '<button class="boton boton-pequeno ' . e($clase) . '" type="submit">' . icono($icono, 15) . ' ' . e($texto) . '</button>'
        . '</form>';
}

/** Enlace con aspecto de botón. */
function enlace_boton(string $direccion, string $texto, string $icono, string $clase = 'boton-secundario boton-pequeno'): string
{
    return '<a class="boton ' . e($clase) . '" href="' . e($direccion) . '">' . icono($icono, 15) . ' ' . e($texto) . '</a>';
}
