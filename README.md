# CARL-HES

**Control y Aprobación de la Revisión y Liberación de HES**

Aplicativo web del proyecto del curso **Gestión de Datos e Información** (Universidad Católica de Santa María, 2026),
Grupo 08 de práctica. Implementa la revisión y liberación de la Hoja de Entrada de Servicio (HES) dentro del proceso de
Seguimiento de Valorizaciones y consume la base de datos `hes_spcc` en MySQL 8.0.

Todos los datos son ficticios y se usan solo con fines académicos.

**Versión 1.0.**

## Tecnologías

| Elemento | Tecnología |
|---|---|
| Lenguaje | PHP 7.4 u 8.x, sin frameworks |
| Conexión con la base | Extensión `mysqli` de PHP, conector nativo de MySQL |
| Gestor | MySQL 8.0, motor InnoDB |
| Lógica de datos | Procedimientos almacenados y triggers |
| Interfaz | HTML y CSS propios, sin frameworks de CSS |
| Servidor web | Servidor incorporado de PHP (o Apache de XAMPP) |
| Lanzador para Windows | `CARL-HES.exe`, escrito en C con la API de Windows (carpeta `lanzador`) |

El aplicativo no usa frameworks ni ORM: abre la conexión con `new mysqli(...)` y ejecuta cada operación con
`CALL procedimiento(?, ...)` en una sentencia preparada. No lee ni modifica tablas directamente.

## Requisitos

- Windows 10 u 11 de 64 bits (para el ejecutable) o cualquier sistema con PHP.
- MySQL Server 8.0 (servicio `MySQL80`, puerto 3306). MySQL Workbench es opcional.
- PHP 7.4 o superior con la extensión `mysqli`. En Windows sirve el PHP de XAMPP; no es necesario iniciar Apache ni
  MySQL de XAMPP.

## Instalación de la base de datos

Opción A, un solo script: en MySQL Workbench, conectado como `root`, abra y ejecute
`sql/CARL-HES_base_de_datos.sql`. También se puede usar `Instalar base de datos.bat` de la carpeta del ejecutable.

Opción B, scripts por separado, en este orden:

| Orden | Script | Contenido |
|---|---|---|
| 1 | `01_crear_base_datos_hes_spcc.sql` | Base `hes_spcc`: 19 tablas, restricciones, índices, vista y triggers de fechas |
| 2 | `02_insertar_datos_hes_spcc.sql` | Datos de enero a septiembre de 2026 (136 HES) |
| 3 | `04_historial_hes_spcc.sql` | Base histórica `hes_spcc_historico` y procedimiento `sp_archivar_historial` |
| 4 | `05_aplicativo_hes_spcc.sql` | Eliminación lógica (columna `Activo`), triggers contra el borrado físico, procedimientos de consulta y usuario `app_hes` |
| 5 | `06_crud_hes_spcc.sql` | Procedimientos y triggers del registro, la edición y la eliminación lógica |
| 6 | `07_reportes_hes_spcc.sql` | Reportes 2 al 13, trabajadores e inspecciones |
| 7 | `08_datos_adicionales_hes_spcc.sql` | Más datos: periodo 10/2026 completo (18 HES), dos contratistas y sus trabajadores |

`03_consultas_hes_spcc.sql` contiene las trece consultas de la Cuarta Entrega y no es necesario para el aplicativo.
Se necesita `root` porque el script 05 crea el usuario `app_hes`. El script 01 elimina y vuelve a crear la base, por
lo que la instalación siempre parte de cero. El script consolidado reúne los siete scripts en ese mismo orden.

## Ejecución

- **Ejecutable (Windows):** doble clic en `CARL-HES.exe`. El lanzador busca PHP (carpeta `php` junto al ejecutable,
  XAMPP o la variable PATH), inicia el servidor de PHP en un puerto libre entre 8080 y 8099 y abre el aplicativo en
  una ventana propia de Microsoft Edge o Google Chrome. Al cerrar la ventana, detiene el servidor.
- **Archivo de respaldo:** `Iniciar_CARL-HES.bat` inicia el servidor de PHP de XAMPP en `http://127.0.0.1:8080`.
- **Apache de XAMPP:** copie la carpeta a `C:\xampp\htdocs\carl-hes`, inicie Apache y abra
  `http://localhost/carl-hes`.

Los datos de conexión están en `config/config.php`.

## Credenciales de prueba

| Dato | Valor |
|---|---|
| Servidor y puerto | `127.0.0.1`, `3306` |
| Base de datos | `hes_spcc` |
| Usuario del aplicativo | `app_hes` (solo permiso `EXECUTE`) |
| Contraseña | `HesApp2026#` |

El aplicativo no tiene inicio de sesión: lo usa la Analista de Contratos en su computadora. Datos útiles para probar:
analista `104390` (Lucía Fernanda Chávez Mamani), periodo `202607`, HES `005214`, inspección `INS-2026-07-007`,
contratista `20487213561` y contrato `CT-004517`.

## Arquitectura

```
Navegador (ventana de CARL-HES)
   │  HTTP 127.0.0.1
   ▼
Páginas PHP (presentación)          index.php, contratistas.php, hes_detalle.php, reportes.php, ...
   │
   ▼
Acceso a datos                      app/datos/*.php  →  un método por procedimiento
   │
   ▼
Conexión nativa (mysqli)            app/Conexion.php  →  CALL sp_...(?, ?)
   │  TCP 3306, usuario app_hes (solo EXECUTE)
   ▼
MySQL 8.0 · base hes_spcc           procedimientos, triggers y tablas
```

El usuario `app_hes` solo tiene el permiso `EXECUTE` sobre `hes_spcc`: puede ejecutar procedimientos, pero no puede
leer ni modificar las tablas directamente. Los procedimientos trabajan con los permisos de quien los creó
(`SQL SECURITY DEFINER`, el valor por defecto de MySQL).

## Módulos

| Módulo | Consultar | Registrar | Editar | Eliminar (lógico) |
|---|---|---|---|---|
| Contratistas (con hasta tres teléfonos) | Sí | Sí | Sí | Baja y reactivación |
| Contratos | Sí | Sí | Sí | Baja y reactivación |
| Analistas | Sí | Sí | Sí | Baja y reactivación |
| Centros de costo | Sí | Sí | Sí | Baja y reactivación |
| Trabajadores | Sí | Sí | Sí | Baja y reactivación |
| HES (con su inspección de obligaciones) | Sí, con detalle | Sí | Fecha y monto, solo pendientes | Anulación (estado Anulada) |
| Observaciones de una HES | Sí | Sí, solo en HES pendientes | Comentario | No se eliminan (son historial) |
| Inspecciones | Sí | Se registran con su HES | No | No |

Una HES pendiente también se puede aprobar, rechazar o retirar.

## Reportes

Los trece reportes se obtienen con procedimientos almacenados y todos combinan tablas con `JOIN`.

| N.º | Reporte | Procedimiento | Parámetros |
|---|---|---|---|
| 1 | HES pendientes de una analista | `sp_rep_hes_pendientes_analista` | Analista |
| 2 | Carga de trabajo por analista | `sp_rep_carga_analistas` | — |
| 3 | Historial de observaciones de una HES | `sp_rep_historial_observaciones` | HES |
| 4 | HES observadas más de una vez | `sp_rep_hes_observadas_reiteradas` | — |
| 5 | Contratistas con HES por subsanar | `sp_rep_contratistas_por_subsanar` | — |
| 6 | Inspecciones con documentación incompleta | `sp_rep_inspecciones_incompletas` | Periodo |
| 7 | Conformidad de las obligaciones de una inspección | `sp_rep_conformidad_inspeccion` | Inspección |
| 8 | Mora del periodo por contratista | `sp_rep_mora_periodo` | Periodo |
| 9 | HES pendientes con mora y su declaración jurada | `sp_rep_hes_mora_declaracion` | — |
| 10 | Pago de CTS y gratificación | `sp_rep_cts_gratificacion` | Periodo y analista |
| 11 | Boletas sin firma frente a la obligación 2.2 | `sp_rep_boletas_sin_firma` | — |
| 12 | HES aprobadas para el memo de facturación | `sp_rep_memo_facturacion` | Periodo y analista |
| 13 | Monto aprobado por centro de costo | `sp_rep_monto_centro_costo` | Periodo |

## Estructura del proyecto

```
CARL-HES/
├── index.php                 Inicio: indicadores, HES por estado y últimas HES
├── conexion.php              Prueba de conexión y de permisos
├── contratistas.php          Contratistas: búsqueda, baja y reactivación
├── contratista_form.php      Registro y edición de una contratista
├── contratos.php             Contratos: búsqueda, baja y reactivación
├── contrato_form.php         Registro y edición de un contrato
├── analistas.php             Analistas: lista, baja y reactivación
├── analista_form.php         Registro y edición de una analista
├── centros_costo.php         Centros de costo: lista, baja y reactivación
├── centro_costo_form.php     Registro y edición de un centro de costo
├── trabajadores.php          Trabajadores: búsqueda, baja y reactivación
├── trabajador_form.php       Registro y edición de un trabajador
├── hes.php                   Búsqueda de HES con filtros de estado y periodo
├── hes_form.php              Registro de una HES y corrección de una HES pendiente
├── hes_detalle.php           Detalle de una HES, cambio de estado, anulación y observaciones
├── observacion_form.php      Corrección del comentario de una observación
├── inspecciones.php          Consulta de inspecciones de obligaciones
├── reportes.php              Trece reportes de la Analista de Contratos
├── Iniciar_CARL-HES.bat      Arranque de respaldo con el PHP de XAMPP
├── config/config.php         Datos de conexión
├── app/
│   ├── inicio.php            Carga común de las páginas
│   ├── Conexion.php          Conexión mysqli y ejecución de procedimientos
│   ├── funciones.php         Formatos, mensajes de error, avisos e íconos
│   ├── plantilla.php         Menú lateral, barra superior, avisos y botones
│   └── datos/                Acceso a datos por entidad (un método por procedimiento)
├── assets/                   Estilos e ícono
├── sql/                      Scripts de la base de datos (01 a 08 y script consolidado)
├── lanzador/                 Código fuente de CARL-HES.exe (C, API de Windows)
└── distribucion/             Archivos de la carpeta del ejecutable (instalación de la base, respaldo, PHP portable)
```

## Procedimientos y triggers

La base tiene **63 procedimientos**: 62 del aplicativo (scripts 05, 06 y 07) y `sp_archivar_historial` (script 04).

| Entidad | Procedimientos |
|---|---|
| General | `sp_info_conexion`, `sp_resumen_inicio`, `sp_hes_por_estado`, `sp_hes_recientes`, `sp_periodo_listar` |
| Contratista | `sp_contratista_buscar`, `sp_contratista_obtener`, `sp_contratista_insertar`, `sp_contratista_actualizar`, `sp_contratista_eliminar`, `sp_contratista_reactivar`, `sp_telefono_reemplazar` |
| Contrato | `sp_contrato_buscar`, `sp_contrato_obtener`, `sp_contrato_insertar`, `sp_contrato_actualizar`, `sp_contrato_eliminar`, `sp_contrato_reactivar` |
| Analista | `sp_analista_listar`, `sp_analista_obtener`, `sp_analista_insertar`, `sp_analista_actualizar`, `sp_analista_eliminar`, `sp_analista_reactivar`, `sp_cargo_listar` |
| Centro de costo | `sp_centro_costo_listar`, `sp_centro_costo_obtener`, `sp_centro_costo_insertar`, `sp_centro_costo_actualizar`, `sp_centro_costo_eliminar`, `sp_centro_costo_reactivar` |
| Trabajador | `sp_trabajador_buscar`, `sp_trabajador_obtener`, `sp_trabajador_insertar`, `sp_trabajador_actualizar`, `sp_trabajador_eliminar`, `sp_trabajador_reactivar` |
| HES | `sp_hes_buscar`, `sp_hes_detalle`, `sp_hes_siguiente_numero`, `sp_hes_registrar`, `sp_hes_actualizar`, `sp_hes_cambiar_estado`, `sp_hes_anular`, `sp_hes_observaciones` |
| Observación | `sp_observacion_obtener`, `sp_observacion_registrar`, `sp_observacion_actualizar` |
| Inspección | `sp_inspeccion_buscar` |
| Reportes | los trece procedimientos `sp_rep_*` de la tabla anterior |

La base tiene **22 triggers**:

| Trigger | Regla |
|---|---|
| `tr_hes_fecha_bi/bu`, `tr_observacion_fecha_bi/bu`, `tr_declara_fecha_bi/bu` | Las fechas no pueden ser posteriores a hoy |
| `tr_contratista_no_borrar`, `tr_contrato_no_borrar`, `tr_analista_no_borrar`, `tr_centro_costo_no_borrar`, `tr_trabajador_no_borrar` | Impiden el borrado físico: se usa la eliminación lógica |
| `tr_contratista_baja_bu` | Una contratista con contratos vigentes no puede darse de baja |
| `tr_contrato_validar_bi`, `tr_contrato_validar_bu` | Un contrato exige contratista, analista y centro de costo vigentes; con HES pendientes no puede darse de baja |
| `tr_analista_baja_bu` | Una analista con contratos vigentes no puede darse de baja |
| `tr_centro_costo_baja_bu` | Un centro de costo con contratos vigentes no puede darse de baja |
| `tr_hes_contrato_bi` | Solo se emiten HES para contratos vigentes |
| `tr_hes_solo_pendiente_bu` | Una HES solo se modifica mientras está pendiente |
| `tr_observacion_hes_pendiente_bi/bu` | Las observaciones solo se registran o editan en HES pendientes |
| `tr_trabajador_validar_bi/bu` | Un trabajador se registra o reactiva solo si su contratista está vigente |

Otras reglas están en los procedimientos: el monto de un contrato no puede quedar por debajo de lo aprobado en HES,
una HES solo se aprueba si el formato está firmado por la contratista y la fecha de emisión no puede ser anterior al
periodo de la inspección. Los procedimientos que escriben en varias tablas trabajan en una transacción. Los formatos
(RUC, DNI, teléfonos y números de contrato, de HES y de registro) los controlan las restricciones `CHECK`. El
aplicativo muestra cada error con un mensaje claro y el código que devolvió MySQL.

## Eliminación lógica

Las tablas CONTRATISTA, CONTRATO, ANALISTA, CENTRO_COSTO y TRABAJADOR tienen la columna `Activo` (1 = vigente,
0 = dado de baja). «Dar de baja» cambia `Activo` a 0 y «Reactivar» lo devuelve a 1; el registro nunca se borra. En las
HES, la baja se registra con el estado `Anulada`.

## Versiones

| Versión | Contenido |
|---|---|
| 0.3 | Conexión y prueba de conexión, inicio, búsqueda de contratistas y de HES, detalle de HES, reporte 1, eliminación lógica y usuario con permiso solo de ejecución |
| 0.7 | Registro, edición y eliminación lógica de contratistas, contratos, analistas y centros de costo; registro, edición, cambio de estado y anulación de HES; observaciones; triggers de validación |
| 1.0 | Trece reportes, trabajadores, inspecciones, script con más datos, lanzador `CARL-HES.exe`, manual de usuario y memoria descriptiva |

## Autores

Grupo 08: Jenifer Huanca Huamani, André Lazo Villavicencio, José Lima Filinich, Gustavo Melo Aranibar y
Carlos Mita Mamani.
