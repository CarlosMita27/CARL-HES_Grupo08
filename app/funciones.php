<?php
/**
 * Funciones de apoyo para mostrar datos en las páginas.
 */

/** Escapa un texto para mostrarlo en HTML. */
function e($texto): string
{
    return htmlspecialchars((string) $texto, ENT_QUOTES, 'UTF-8');
}

/** Lee un parámetro de la dirección (GET) sin espacios sobrantes. */
function parametro(string $nombre, string $defecto = ''): string
{
    return trim((string) ($_GET[$nombre] ?? $defecto));
}

/** Monto en soles: S/ 117,684.39 */
function moneda($monto): string
{
    return 'S/ ' . number_format((float) $monto, 2, '.', ',');
}

/** Fecha aaaa-mm-dd en formato dd/mm/aaaa. */
function fecha(?string $valor): string
{
    if (!$valor) {
        return '—';
    }
    $f = DateTime::createFromFormat('Y-m-d', substr($valor, 0, 10));
    return $f ? $f->format('d/m/Y') : $valor;
}

/** Fecha y hora en formato dd/mm/aaaa hh:mm:ss. */
function fecha_hora(?string $valor): string
{
    $f = $valor ? DateTime::createFromFormat('Y-m-d H:i:s', $valor) : false;
    return $f ? $f->format('d/m/Y H:i:s') : (string) $valor;
}

/** Periodo aaaamm como texto: 202607 → Julio 2026. */
function periodo_texto(?string $periodo): string
{
    $meses = [1 => 'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio',
              'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'];
    $mes = (int) substr((string) $periodo, 4, 2);
    return isset($meses[$mes]) ? $meses[$mes] . ' ' . substr($periodo, 0, 4) : (string) $periodo;
}

/** Periodo aaaamm abreviado: 202607 → Jul. 2026. */
function periodo_corto(?string $periodo): string
{
    $meses = [1 => 'Ene.', 'Feb.', 'Mar.', 'Abr.', 'May.', 'Jun.', 'Jul.', 'Ago.', 'Set.', 'Oct.', 'Nov.', 'Dic.'];
    $mes = (int) substr((string) $periodo, 4, 2);
    return isset($meses[$mes]) ? $meses[$mes] . ' ' . substr($periodo, 0, 4) : (string) $periodo;
}

/** Etiqueta de color para el estado de una HES. */
function insignia_estado(string $estado): string
{
    $clase = strtolower(strtr($estado, ['á' => 'a', 'é' => 'e', 'í' => 'i', 'ó' => 'o', 'ú' => 'u']));
    return '<span class="insignia insignia-' . e($clase) . '">' . e($estado) . '</span>';
}

/** Etiqueta Activo / Inactivo de la eliminación lógica. */
function insignia_activo($activo): string
{
    return (int) $activo === 1
        ? '<span class="insignia insignia-activo">Activo</span>'
        : '<span class="insignia insignia-inactivo">Inactivo</span>';
}

/** Explica en lenguaje sencillo los errores de MySQL más frecuentes. */
function explicar_error(mysqli_sql_exception $e): string
{
    switch ($e->getCode()) {
        case 1045:
            return 'Usuario o contraseña incorrectos.';
        case 1044:
            return 'El usuario no tiene permiso para usar esa base de datos.';
        case 1049:
            return 'La base de datos no existe. Ejecute los scripts 01, 02, 04 y 05.';
        case 1142:
            return 'El usuario no tiene permiso para leer o modificar esa tabla directamente.';
        case 1305:
            return 'El procedimiento no existe. Ejecute el script 05 en MySQL Workbench.';
        case 1370:
            return 'El usuario no tiene permiso para ejecutar el procedimiento.';
        case 2002:
        case 2003:
            return 'No se pudo llegar al servidor MySQL. Verifique que el servicio MySQL80 esté iniciado y que el servidor y el puerto sean correctos.';
        case 2054:
            return 'El método de autenticación del usuario no es compatible con el conector de PHP.';
        default:
            return 'Revise el mensaje de MySQL para identificar la causa.';
    }
}

/** Nota con el procedimiento almacenado que entrega los datos de la sección. */
function fuente(string $llamada, string $texto = 'Datos obtenidos con'): string
{
    return '<p class="fuente">' . e($texto) . ' <code>CALL ' . e($llamada) . '</code></p>';
}

/** Ícono SVG de trazo simple. */
function icono(string $nombre, int $tamano = 18): string
{
    $trazos = [
        'inicio'        => '<path d="M3 11.5 12 4l9 7.5"/><path d="M5.5 10v10h13V10"/><path d="M10 20v-5h4v5"/>',
        'conexion'      => '<ellipse cx="12" cy="5.5" rx="7.5" ry="2.8"/><path d="M4.5 5.5v13c0 1.5 3.4 2.8 7.5 2.8s7.5-1.3 7.5-2.8v-13"/><path d="M4.5 12c0 1.5 3.4 2.8 7.5 2.8s7.5-1.3 7.5-2.8"/>',
        'contratistas'  => '<rect x="4.5" y="3" width="15" height="18" rx="1.5"/><path d="M9 7.5h1.5M13.5 7.5H15M9 11.5h1.5M13.5 11.5H15M9 15.5h1.5M13.5 15.5H15"/>',
        'hes'           => '<path d="M14 3H6.5A1.5 1.5 0 0 0 5 4.5v15A1.5 1.5 0 0 0 6.5 21h11a1.5 1.5 0 0 0 1.5-1.5V8z"/><path d="M14 3v5h5M8.5 13h7M8.5 17h5"/>',
        'contratos'     => '<rect x="5" y="4" width="14" height="17" rx="2"/><path d="M9 4V2.8h6V4M8.5 10h7M8.5 14h7M8.5 18h4"/>',
        'analistas'     => '<circle cx="9" cy="8" r="3.5"/><path d="M2.8 20c.8-3.4 3.3-5.4 6.2-5.4s5.4 2 6.2 5.4"/><path d="M15.5 4.6a3.5 3.5 0 0 1 0 6.8M17.6 14.9c1.7.8 2.9 2.4 3.4 5.1"/>',
        'inspecciones'  => '<rect x="4" y="4" width="16" height="16" rx="2.5"/><path d="m8 12.3 2.8 2.8L16.2 9"/>',
        'observaciones' => '<path d="M4 5h16v11H9.5L4 20z"/><path d="M8 9.5h8M8 12.5h5"/>',
        'reportes'      => '<path d="M3.5 20.5h17"/><rect x="5.5" y="11" width="3" height="6.5" rx=".5"/><rect x="10.5" y="5.5" width="3" height="12" rx=".5"/><rect x="15.5" y="13.5" width="3" height="4" rx=".5"/>',
        'buscar'        => '<circle cx="11" cy="11" r="6.5"/><path d="m20 20-4.2-4.2"/>',
        'mas'           => '<path d="M12 5v14M5 12h14"/>',
        'imprimir'      => '<path d="M7 9V3.5h10V9"/><rect x="3.5" y="9" width="17" height="8" rx="1.5"/><path d="M7 14h10v6.5H7z"/>',
        'correcto'      => '<circle cx="12" cy="12" r="9"/><path d="m8 12.5 2.7 2.7L16.5 9.5"/>',
        'error'         => '<circle cx="12" cy="12" r="9"/><path d="M12 7.5v5.5M12 16.5h.01"/>',
        'escudo'        => '<path d="M12 3 5 6v5.5c0 4.4 3 8 7 9.5 4-1.5 7-5.1 7-9.5V6z"/><path d="m9 12 2.2 2.2L15.5 10"/>',
        'volver'        => '<path d="m14.5 18-6-6 6-6"/>',
        'reloj'         => '<circle cx="12" cy="12" r="9"/><path d="M12 7v5l3.2 2"/>',
        'monto'         => '<rect x="3" y="6" width="18" height="12" rx="2"/><circle cx="12" cy="12" r="2.6"/><path d="M6.5 9.5v5M17.5 9.5v5"/>',
        'pendiente'     => '<circle cx="12" cy="12" r="9"/><path d="M12 7v5l3.2 2"/>',
        'aprobada'      => '<circle cx="12" cy="12" r="9"/><path d="m8 12.5 2.7 2.7L16.5 9.5"/>',
        'centros'       => '<path d="m12 3 9 5-9 5-9-5z"/><path d="m3 12.5 9 5 9-5"/><path d="m3 17 9 5 9-5"/>',
        'trabajadores'  => '<circle cx="12" cy="8" r="4"/><path d="M4.5 21c1-4 4-6 7.5-6s6.5 2 7.5 6"/>',
        'editar'        => '<path d="M4 20h4L19 9a2.1 2.1 0 0 0-3-3L5 17z"/><path d="m14.5 7.5 3 3"/>',
        'baja'          => '<circle cx="12" cy="12" r="9"/><path d="m9 9 6 6M15 9l-6 6"/>',
        'reactivar'     => '<path d="M4.5 12a7.5 7.5 0 1 0 2.2-5.3"/><path d="M4.5 4.5v4h4"/>',
        'anular'        => '<circle cx="12" cy="12" r="9"/><path d="m5.7 5.7 12.6 12.6"/>',
        'retirar'       => '<path d="M9 14 4 9l5-5"/><path d="M4 9h10.5a5.5 5.5 0 0 1 0 11H12"/>',
        'guardar'       => '<path d="m5 12.5 4.5 4.5L19 7.5"/>',
    ];
    $trazo = $trazos[$nombre] ?? '';
    return '<svg class="icono" width="' . $tamano . '" height="' . $tamano . '" viewBox="0 0 24 24" fill="none" '
        . 'stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">'
        . $trazo . '</svg>';
}

/** Indica si la página recibió un formulario (método POST). */
function es_post(): bool
{
    return ($_SERVER['REQUEST_METHOD'] ?? 'GET') === 'POST';
}

/** Lee un campo del formulario sin espacios sobrantes. */
function valor_post(string $nombre): string
{
    return trim((string) ($_POST[$nombre] ?? ''));
}

/** Convierte un texto vacío en NULL, para enviarlo así a MySQL. */
function nulo_si_vacio(string $valor): ?string
{
    return $valor === '' ? null : $valor;
}

/** Redirige a otra página y termina la ejecución. */
function redirigir(string $direccion): void
{
    header('Location: ' . $direccion);
    exit;
}

/** Guarda un aviso para mostrarlo en la siguiente página (correcto o error). */
function avisar(string $tipo, string $texto, string $detalle = ''): void
{
    $_SESSION['aviso'] = ['tipo' => $tipo, 'texto' => $texto, 'detalle' => $detalle];
}

/** Devuelve el aviso pendiente y lo borra. */
function tomar_aviso(): ?array
{
    $aviso = $_SESSION['aviso'] ?? null;
    unset($_SESSION['aviso']);
    return $aviso;
}

/** Guarda como aviso el error que devolvió MySQL al ejecutar una operación. */
function avisar_error(mysqli_sql_exception $e): void
{
    avisar('error', mensaje_error($e), 'Error ' . $e->getCode() . ' de MySQL: ' . $e->getMessage());
}

/**
 * Traduce a un mensaje claro los errores que devuelve MySQL al registrar o modificar datos:
 * restricciones CHECK, claves repetidas, datos demasiado largos y mensajes de triggers.
 */
function mensaje_error(mysqli_sql_exception $e): string
{
    $codigo = $e->getCode();
    $texto = $e->getMessage();

    if ($codigo === 1644) {
        return $texto;
    }
    if ($codigo === 3819 && preg_match("/'([a-z_]+)'/", $texto, $m)) {
        $restricciones = [
            'ck_contratista_ruc'                 => 'El RUC debe tener exactamente 11 dígitos.',
            'ck_telefono_contratista_telefono'   => 'Cada teléfono debe tener exactamente 9 dígitos.',
            'ck_contrato_num'                    => 'El número de contrato debe tener el formato CT-000000.',
            'ck_contrato_monto'                  => 'El monto total del contrato debe ser mayor que cero.',
            'ck_analista_registro'               => 'El número de registro debe tener exactamente 6 dígitos.',
            'ck_centro_costo_cod'                => 'El código del centro de costo solo admite letras y números, sin espacios.',
            'ck_hes_num'                         => 'El número de HES debe tener exactamente 6 dígitos.',
            'ck_hes_monto'                       => 'El monto del servicio debe ser mayor que cero.',
            'ck_inspeccion_obligaciones_num'     => 'El periodo de la inspección no es válido.',
            'ck_inspeccion_obligaciones_periodo' => 'El periodo de la inspección no es válido.',
            'ck_trabajador_dni'                  => 'El DNI debe tener exactamente 8 dígitos.',
        ];
        return $restricciones[$m[1]] ?? 'Un dato no cumple el formato requerido.';
    }
    if ($codigo === 1062) {
        $claves = [
            'CONTRATISTA.PRIMARY'                              => 'Ya existe una contratista con ese RUC.',
            'CONTRATO.PRIMARY'                                 => 'Ya existe un contrato con ese número.',
            'ANALISTA.PRIMARY'                                 => 'Ya existe una analista con ese número de registro.',
            'CENTRO_COSTO.PRIMARY'                             => 'Ya existe un centro de costo con ese código.',
            'CENTRO_COSTO.uq_centro_costo_nombre_centro_costo' => 'Ya existe un centro de costo con ese nombre.',
            'HES.PRIMARY'                                      => 'Ya existe una HES con ese número.',
            'TELEFONO_CONTRATISTA.PRIMARY'                     => 'Un teléfono está repetido.',
            'TRABAJADOR.PRIMARY'                               => 'Ya existe un trabajador con ese DNI.',
        ];
        foreach ($claves as $clave => $mensaje) {
            if (strpos($texto, "'" . $clave . "'") !== false) {
                return $mensaje;
            }
        }
        return 'Ya existe un registro con ese código.';
    }
    if ($codigo === 1406 && preg_match("/column '([A-Za-z_]+)'/", $texto, $m)) {
        $largos = [
            'RUC'                 => 'El RUC debe tener exactamente 11 dígitos.',
            'DNI'                 => 'El DNI debe tener exactamente 8 dígitos.',
            'Telefono'            => 'Cada teléfono debe tener exactamente 9 dígitos.',
            'Num_contrato'        => 'El número de contrato debe tener el formato CT-000000.',
            'Num_registro'        => 'El número de registro debe tener exactamente 6 dígitos.',
            'Num_HES'             => 'El número de HES debe tener exactamente 6 dígitos.',
            'Razon_social'        => 'La razón social admite hasta 100 caracteres.',
            'Apellidos'           => 'Los apellidos admiten hasta 50 caracteres.',
            'Nombres'             => 'Los nombres admiten hasta 50 caracteres.',
            'Cod_centro_costo'    => 'El código del centro de costo admite hasta 10 caracteres.',
            'Nombre_centro_costo' => 'El nombre del centro de costo admite hasta 80 caracteres.',
            'Comentario'          => 'El comentario admite hasta 500 caracteres.',
        ];
        return $largos[$m[1]] ?? 'Un dato es demasiado largo.';
    }
    switch ($codigo) {
        case 1048:
            return 'Falta completar un campo obligatorio.';
        case 1366:
            return 'Un valor numérico no es válido. Use punto para los decimales, por ejemplo 1500.50.';
        case 1264:
            return 'El monto es demasiado grande.';
        case 1292:
            return 'La fecha no es válida.';
        case 1265:
            return 'Uno de los valores elegidos no está permitido.';
        case 1452:
            return 'El registro relacionado no existe.';
    }
    return explicar_error($e);
}

/** Encabezado legible de una columna de reporte. */
function titulo_columna(string $columna): string
{
    $titulos = [
        'Num_HES' => 'N.º HES', 'Num_registro' => 'Registro', 'Razon_social' => 'Contratista',
        'Num_contrato' => 'Contrato', 'Num_inspeccion' => 'Inspección', 'Num_observacion' => 'N.º',
        'Fecha_emision' => 'Emisión', 'Fecha_observacion' => 'Fecha', 'Dias_en_espera' => 'Días',
        'Monto_servicio' => 'Monto', 'Contratos_a_cargo' => 'Contratos', 'HES_pendientes' => 'HES pendientes',
        'Veces_observada' => 'Veces', 'Primera_observacion' => 'Primera', 'Ultima_observacion' => 'Última',
        'HES_por_subsanar' => 'HES por subsanar', 'Telefonos' => 'Teléfonos', 'Firma_contratista' => 'Firma',
        'Reportes_entidad' => 'Reportes', 'Cod_obligacion' => 'Cód.', 'Obligacion' => 'Obligación',
        'Monto_declarado' => 'Declarado', 'Monto_adeudado' => 'Adeudado (reporte)',
        'Monto_pagado' => 'Pagado (formato)', 'Monto_pagado_reporte' => 'Pagado (reporte)',
        'Fecha_pago' => 'Fecha de pago', 'Mora_total' => 'Mora total', 'Num_declaracion' => 'Declaración jurada',
        'Fecha_compromiso_pago' => 'Compromiso de pago', 'Situacion' => 'Situación', 'Gratificacion' => 'Gratificación',
        'Boletas_sin_firma' => 'Sin firma', 'Centro_de_costo' => 'Centro de costo', 'Cod_centro_costo' => 'Código',
        'HES_aprobadas' => 'HES aprobadas', 'Monto_total' => 'Monto total',
    ];
    return $titulos[$columna] ?? str_replace('_', ' ', $columna);
}

/** Celda de un reporte con el formato de su columna: [clase CSS, contenido HTML]. */
function celda_reporte(string $columna, $valor): array
{
    $montos = ['Monto_servicio', 'Monto_total', 'Monto_declarado', 'Monto_adeudado', 'Monto_pagado',
               'Monto_pagado_reporte', 'Declarado', 'Pagado', 'Mora', 'Mora_total'];
    $fechas = ['Fecha_emision', 'Fecha_observacion', 'Primera_observacion', 'Ultima_observacion',
               'Fecha_pago', 'Fecha_compromiso_pago'];
    $conteos = ['Contratos_a_cargo', 'HES_pendientes', 'Veces_observada', 'HES_por_subsanar', 'Reportes_entidad',
                'Boletas', 'Boletas_sin_firma', 'HES_aprobadas', 'Num_observacion'];
    $codigos = ['Num_registro', 'Num_contrato', 'Num_inspeccion', 'Cod_obligacion', 'Cod_centro_costo', 'RUC',
                'Num_declaracion'];
    $tonos = [
        'Conforme' => 'aprobada', 'Observado' => 'rechazada',
        'Pagado' => 'aprobada', 'Pago incompleto' => 'rechazada', 'No aplica' => 'anulada',
        'Declaración vigente' => 'aprobada', 'Compromiso vencido' => 'pendiente',
        'Sin declaración jurada' => 'rechazada', 'Firmado' => 'aprobada', 'No firmado' => 'rechazada',
    ];

    if ($valor === null || $valor === '') {
        return ['', '<span class="suave">—</span>'];
    }
    if (in_array($columna, $montos, true)) {
        return ['derecha sin-salto', moneda($valor)];
    }
    if (in_array($columna, $fechas, true)) {
        return ['sin-salto', fecha($valor)];
    }
    if ($columna === 'Dias_en_espera') {
        $tono = (int) $valor > 60 ? 'contador-rojo' : 'contador-ambar';
        return ['centro', '<span class="contador ' . $tono . '">' . (int) $valor . '</span>'];
    }
    if (in_array($columna, $conteos, true)) {
        return ['centro', '<span class="contador">' . (int) $valor . '</span>'];
    }
    if ($columna === 'Num_HES') {
        return ['', '<a class="enlace codigo" href="hes_detalle.php?num=' . e(rawurlencode($valor)) . '">' . e($valor) . '</a>'];
    }
    if (in_array($columna, $codigos, true)) {
        return ['codigo sin-salto', e($valor)];
    }
    if ($columna === 'Estado') {
        return ['', insignia_estado($valor)];
    }
    if ($columna === 'Periodo') {
        return ['sin-salto', e(periodo_corto($valor))];
    }
    if (isset($tonos[$valor])) {
        return ['sin-salto', '<span class="insignia insignia-' . $tonos[$valor] . '">' . e($valor) . '</span>'];
    }
    return ['', e($valor)];
}
