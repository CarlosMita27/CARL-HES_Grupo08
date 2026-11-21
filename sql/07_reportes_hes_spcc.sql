-- ============================================================================
-- Base de datos: revisión y liberación de la HES (SPCC) - Software CARL-HES
-- Gestión de Datos e Información - UCSM. Quinta Entrega: aplicativo (versión 1.0)
-- Gestor: MySQL 8.0 con el motor InnoDB
-- Contenido: procedimientos de los reportes 2 a 13 (el reporte 1 está en el
--            script 05), CRUD de trabajadores y consulta de inspecciones.
-- Orden: ejecutar después de 01, 02, 04, 05 y 06. Se puede volver a ejecutar.
-- ============================================================================

SET NAMES utf8mb4;
USE hes_spcc;

-- ----------------------------------------------------------------------------
-- TRIGGERS DE TRABAJADOR
-- ----------------------------------------------------------------------------
DROP TRIGGER IF EXISTS tr_trabajador_validar_bi;
DROP TRIGGER IF EXISTS tr_trabajador_validar_bu;

DELIMITER $$

-- Un trabajador nuevo debe pertenecer a una contratista vigente
CREATE TRIGGER tr_trabajador_validar_bi BEFORE INSERT ON TRABAJADOR
FOR EACH ROW
BEGIN
  IF NOT EXISTS (SELECT 1 FROM CONTRATISTA WHERE RUC = NEW.RUC AND Activo = 1) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La contratista no existe o está dada de baja';
  END IF;
END$$

-- Al editar o reactivar a un trabajador, su contratista debe estar vigente
CREATE TRIGGER tr_trabajador_validar_bu BEFORE UPDATE ON TRABAJADOR
FOR EACH ROW
BEGIN
  IF NEW.Activo = 1 AND NOT EXISTS (SELECT 1 FROM CONTRATISTA WHERE RUC = NEW.RUC AND Activo = 1) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La contratista del trabajador está dada de baja';
  END IF;
END$$

DELIMITER ;

-- ----------------------------------------------------------------------------
-- PROCEDIMIENTOS
-- ----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_trabajador_buscar;
DROP PROCEDURE IF EXISTS sp_trabajador_obtener;
DROP PROCEDURE IF EXISTS sp_trabajador_insertar;
DROP PROCEDURE IF EXISTS sp_trabajador_actualizar;
DROP PROCEDURE IF EXISTS sp_trabajador_eliminar;
DROP PROCEDURE IF EXISTS sp_trabajador_reactivar;
DROP PROCEDURE IF EXISTS sp_inspeccion_buscar;
DROP PROCEDURE IF EXISTS sp_rep_carga_analistas;
DROP PROCEDURE IF EXISTS sp_rep_historial_observaciones;
DROP PROCEDURE IF EXISTS sp_rep_hes_observadas_reiteradas;
DROP PROCEDURE IF EXISTS sp_rep_contratistas_por_subsanar;
DROP PROCEDURE IF EXISTS sp_rep_inspecciones_incompletas;
DROP PROCEDURE IF EXISTS sp_rep_conformidad_inspeccion;
DROP PROCEDURE IF EXISTS sp_rep_mora_periodo;
DROP PROCEDURE IF EXISTS sp_rep_hes_mora_declaracion;
DROP PROCEDURE IF EXISTS sp_rep_cts_gratificacion;
DROP PROCEDURE IF EXISTS sp_rep_boletas_sin_firma;
DROP PROCEDURE IF EXISTS sp_rep_memo_facturacion;
DROP PROCEDURE IF EXISTS sp_rep_monto_centro_costo;

DELIMITER $$

-- ----------------------------------------------------------------- TRABAJADOR

-- Búsqueda de trabajadores por DNI, nombre o contratista
CREATE PROCEDURE sp_trabajador_buscar(IN p_texto VARCHAR(100), IN p_incluir_inactivos TINYINT)
BEGIN
  SELECT t.DNI, t.Apellidos, t.Nombres, t.RUC, ct.Razon_social,
         (SELECT COUNT(*) FROM BOLETA_PAGO b WHERE b.DNI = t.DNI) AS Boletas,
         t.Activo
  FROM TRABAJADOR t
  JOIN CONTRATISTA ct ON ct.RUC = t.RUC
  WHERE (p_texto IS NULL OR p_texto = ''
         OR t.DNI LIKE CONCAT('%', p_texto, '%')
         OR t.Apellidos LIKE CONCAT('%', p_texto, '%')
         OR t.Nombres LIKE CONCAT('%', p_texto, '%')
         OR ct.Razon_social LIKE CONCAT('%', p_texto, '%'))
    AND (p_incluir_inactivos = 1 OR t.Activo = 1)
  ORDER BY t.Apellidos, t.Nombres;
END$$

CREATE PROCEDURE sp_trabajador_obtener(IN p_dni VARCHAR(20))
BEGIN
  SELECT t.DNI, t.Apellidos, t.Nombres, t.RUC, ct.Razon_social, t.Activo
  FROM TRABAJADOR t
  JOIN CONTRATISTA ct ON ct.RUC = t.RUC
  WHERE t.DNI = p_dni;
END$$

CREATE PROCEDURE sp_trabajador_insertar(IN p_dni VARCHAR(20), IN p_apellidos VARCHAR(100),
                                        IN p_nombres VARCHAR(100), IN p_ruc VARCHAR(20))
BEGIN
  IF NULLIF(TRIM(p_apellidos), '') IS NULL OR NULLIF(TRIM(p_nombres), '') IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Los apellidos y los nombres son obligatorios';
  END IF;
  INSERT INTO TRABAJADOR (DNI, Apellidos, Nombres, RUC)
  VALUES (TRIM(p_dni), TRIM(p_apellidos), TRIM(p_nombres), p_ruc);
END$$

-- El trabajador no cambia de contratista: sus boletas pertenecen a ella
CREATE PROCEDURE sp_trabajador_actualizar(IN p_dni VARCHAR(20), IN p_apellidos VARCHAR(100), IN p_nombres VARCHAR(100))
BEGIN
  IF NOT EXISTS (SELECT 1 FROM TRABAJADOR WHERE DNI = p_dni) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El trabajador no existe';
  END IF;
  IF NULLIF(TRIM(p_apellidos), '') IS NULL OR NULLIF(TRIM(p_nombres), '') IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Los apellidos y los nombres son obligatorios';
  END IF;
  UPDATE TRABAJADOR SET Apellidos = TRIM(p_apellidos), Nombres = TRIM(p_nombres) WHERE DNI = p_dni;
END$$

CREATE PROCEDURE sp_trabajador_eliminar(IN p_dni VARCHAR(20))
BEGIN
  IF NOT EXISTS (SELECT 1 FROM TRABAJADOR WHERE DNI = p_dni) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El trabajador no existe';
  END IF;
  UPDATE TRABAJADOR SET Activo = 0 WHERE DNI = p_dni;
END$$

CREATE PROCEDURE sp_trabajador_reactivar(IN p_dni VARCHAR(20))
BEGIN
  IF NOT EXISTS (SELECT 1 FROM TRABAJADOR WHERE DNI = p_dni) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El trabajador no existe';
  END IF;
  UPDATE TRABAJADOR SET Activo = 1 WHERE DNI = p_dni;
END$$

-- ---------------------------------------------------------------- INSPECCIÓN

-- Inspecciones de obligaciones con su HES y la documentación presentada
CREATE PROCEDURE sp_inspeccion_buscar(IN p_texto VARCHAR(100), IN p_periodo VARCHAR(10))
BEGIN
  SELECT i.Num_inspeccion, i.Periodo, i.Firma_contratista,
         h.Num_HES, h.Estado, ct.Razon_social,
         (SELECT COUNT(*) FROM REPORTE_ENTIDAD r WHERE r.Num_inspeccion = i.Num_inspeccion) AS Reportes,
         (SELECT COUNT(*) FROM BOLETA_PAGO b WHERE b.Num_inspeccion = i.Num_inspeccion) AS Boletas,
         (SELECT COUNT(*) FROM BOLETA_PAGO b
           WHERE b.Num_inspeccion = i.Num_inspeccion AND b.Firma_trabajador = 'No firmada') AS Boletas_sin_firma,
         (SELECT COUNT(*) FROM DECLARACION_JURADA d WHERE d.Num_inspeccion = i.Num_inspeccion) AS Declaraciones
  FROM INSPECCION_OBLIGACIONES i
  JOIN HES h          ON h.Num_inspeccion = i.Num_inspeccion
  JOIN CONTRATO c     ON c.Num_contrato = h.Num_contrato
  JOIN CONTRATISTA ct ON ct.RUC = c.RUC
  WHERE (p_texto IS NULL OR p_texto = ''
         OR i.Num_inspeccion LIKE CONCAT('%', p_texto, '%')
         OR h.Num_HES LIKE CONCAT('%', p_texto, '%')
         OR ct.Razon_social LIKE CONCAT('%', p_texto, '%'))
    AND (p_periodo IS NULL OR p_periodo = '' OR i.Periodo = p_periodo)
  ORDER BY i.Periodo DESC, i.Num_inspeccion;
END$$

-- ------------------------------------------------------------------ REPORTES

-- Reporte 2: carga de trabajo de cada analista (contratos a cargo y HES pendientes)
CREATE PROCEDURE sp_rep_carga_analistas()
BEGIN
  SELECT a.Num_registro,
         CONCAT(a.Apellidos, ', ', a.Nombres) AS Analista,
         COUNT(DISTINCT c.Num_contrato) AS Contratos_a_cargo,
         COALESCE(SUM(h.Estado = 'Pendiente'), 0) AS HES_pendientes
  FROM ANALISTA a
  LEFT JOIN CONTRATO c ON c.Num_registro_analista = a.Num_registro
  LEFT JOIN HES h      ON h.Num_contrato = c.Num_contrato
  WHERE a.Activo = 1
  GROUP BY a.Num_registro, a.Apellidos, a.Nombres
  ORDER BY HES_pendientes DESC, Analista;
END$$

-- Reporte 3: historial de observaciones de una HES
CREATE PROCEDURE sp_rep_historial_observaciones(IN p_num_hes VARCHAR(20))
BEGIN
  SELECT h.Num_HES, ct.Razon_social, h.Estado,
         o.Num_observacion, o.Fecha_observacion, o.Comentario
  FROM OBSERVACION o
  JOIN HES h          ON h.Num_HES = o.Num_HES
  JOIN CONTRATO c     ON c.Num_contrato = h.Num_contrato
  JOIN CONTRATISTA ct ON ct.RUC = c.RUC
  WHERE o.Num_HES = p_num_hes
  ORDER BY o.Num_observacion;
END$$

-- Reporte 4: HES observadas más de una vez
CREATE PROCEDURE sp_rep_hes_observadas_reiteradas()
BEGIN
  SELECT h.Num_HES, ct.Razon_social, h.Estado,
         COUNT(*) AS Veces_observada,
         MIN(o.Fecha_observacion) AS Primera_observacion,
         MAX(o.Fecha_observacion) AS Ultima_observacion
  FROM OBSERVACION o
  JOIN HES h          ON h.Num_HES = o.Num_HES
  JOIN CONTRATO c     ON c.Num_contrato = h.Num_contrato
  JOIN CONTRATISTA ct ON ct.RUC = c.RUC
  GROUP BY h.Num_HES, ct.Razon_social, h.Estado
  HAVING COUNT(*) > 1
  ORDER BY Veces_observada DESC, h.Num_HES;
END$$

-- Reporte 5: contratistas con HES observadas pendientes de subsanar, con sus teléfonos
CREATE PROCEDURE sp_rep_contratistas_por_subsanar()
BEGIN
  SELECT ct.RUC, ct.Razon_social,
         COUNT(DISTINCT h.Num_HES) AS HES_por_subsanar,
         (SELECT GROUP_CONCAT(t.Telefono ORDER BY t.Telefono SEPARATOR ', ')
            FROM TELEFONO_CONTRATISTA t WHERE t.RUC = ct.RUC) AS Telefonos
  FROM CONTRATISTA ct
  JOIN CONTRATO c ON c.RUC = ct.RUC
  JOIN HES h      ON h.Num_contrato = c.Num_contrato
  WHERE h.Estado = 'Pendiente'
    AND EXISTS (SELECT 1 FROM OBSERVACION o WHERE o.Num_HES = h.Num_HES)
  GROUP BY ct.RUC, ct.Razon_social
  ORDER BY HES_por_subsanar DESC, ct.Razon_social;
END$$

-- Reporte 6: inspecciones del periodo con documentación incompleta
CREATE PROCEDURE sp_rep_inspecciones_incompletas(IN p_periodo VARCHAR(10))
BEGIN
  SELECT i.Num_inspeccion, h.Num_HES, ct.Razon_social, i.Firma_contratista,
         (SELECT COUNT(*) FROM REPORTE_ENTIDAD re WHERE re.Num_inspeccion = i.Num_inspeccion) AS Reportes_entidad,
         (SELECT COUNT(*) FROM BOLETA_PAGO b WHERE b.Num_inspeccion = i.Num_inspeccion) AS Boletas
  FROM INSPECCION_OBLIGACIONES i
  JOIN HES h          ON h.Num_inspeccion = i.Num_inspeccion
  JOIN CONTRATO c     ON c.Num_contrato = h.Num_contrato
  JOIN CONTRATISTA ct ON ct.RUC = c.RUC
  WHERE i.Periodo = p_periodo
    AND (i.Firma_contratista = 'No firmado'
         OR NOT EXISTS (SELECT 1 FROM REPORTE_ENTIDAD re WHERE re.Num_inspeccion = i.Num_inspeccion)
         OR NOT EXISTS (SELECT 1 FROM BOLETA_PAGO b WHERE b.Num_inspeccion = i.Num_inspeccion))
  ORDER BY ct.Razon_social;
END$$

-- Reporte 7: conformidad de las obligaciones de una inspección (formato frente a los reportes
-- de las entidades). La conformidad es un dato derivado: se calcula, no se guarda.
CREATE PROCEDURE sp_rep_conformidad_inspeccion(IN p_num_inspeccion VARCHAR(20))
BEGIN
  SELECT d.Cod_obligacion, ot.Nom_obligacion AS Obligacion,
         d.Monto_declarado, r.Monto_adeudado,
         d.Monto_pagado, r.Monto_pagado_rep AS Monto_pagado_reporte,
         CASE WHEN d.Monto_declarado = r.Monto_adeudado
               AND d.Monto_pagado = r.Monto_pagado_rep THEN 'Conforme'
              ELSE 'Observado' END AS Conformidad
  FROM DECLARA d
  JOIN OBLIGACION_TRIBUTARIA ot ON ot.Cod_obligacion = d.Cod_obligacion
  LEFT JOIN (SELECT re.Num_inspeccion, rs.Cod_obligacion,
                    SUM(rs.Monto_adeudado) AS Monto_adeudado,
                    SUM(rs.Monto_pagado_rep) AS Monto_pagado_rep
             FROM REPORTE_ENTIDAD re
             JOIN RESPALDA rs ON rs.Num_reporte = re.Num_reporte
             GROUP BY re.Num_inspeccion, rs.Cod_obligacion) r
         ON r.Num_inspeccion = d.Num_inspeccion AND r.Cod_obligacion = d.Cod_obligacion
  WHERE d.Num_inspeccion = p_num_inspeccion
    AND d.Monto_declarado IS NOT NULL
    AND d.Cod_obligacion NOT IN ('1.8', '1.9')
  ORDER BY CAST(SUBSTRING_INDEX(d.Cod_obligacion, '.', -1) AS UNSIGNED);
END$$

-- Reporte 8: mora del periodo por contratista y obligación
CREATE PROCEDURE sp_rep_mora_periodo(IN p_periodo VARCHAR(10))
BEGIN
  SELECT ct.Razon_social, h.Num_HES, h.Estado, ot.Nom_obligacion AS Obligacion,
         d.Monto_declarado AS Declarado, d.Monto_pagado AS Pagado, d.Mora, d.Fecha_pago
  FROM DECLARA d
  JOIN OBLIGACION_TRIBUTARIA ot  ON ot.Cod_obligacion = d.Cod_obligacion
  JOIN INSPECCION_OBLIGACIONES i ON i.Num_inspeccion = d.Num_inspeccion
  JOIN HES h                     ON h.Num_inspeccion = i.Num_inspeccion
  JOIN CONTRATO c                ON c.Num_contrato = h.Num_contrato
  JOIN CONTRATISTA ct            ON ct.RUC = c.RUC
  WHERE i.Periodo = p_periodo AND d.Mora > 0
  ORDER BY ct.Razon_social, d.Mora DESC;
END$$

-- Reporte 9: HES pendientes con mora y la situación de su declaración jurada
CREATE PROCEDURE sp_rep_hes_mora_declaracion()
BEGIN
  SELECT h.Num_HES, i.Periodo, ct.Razon_social, m.Mora_total,
         dj.Num_declaracion, dj.Fecha_compromiso_pago,
         CASE WHEN dj.Num_declaracion IS NULL THEN 'Sin declaración jurada'
              WHEN dj.Fecha_compromiso_pago < CURDATE() THEN 'Compromiso vencido'
              ELSE 'Declaración vigente' END AS Situacion
  FROM (SELECT Num_inspeccion, SUM(Mora) AS Mora_total
        FROM DECLARA WHERE Mora > 0 GROUP BY Num_inspeccion) m
  JOIN INSPECCION_OBLIGACIONES i  ON i.Num_inspeccion = m.Num_inspeccion
  JOIN HES h                      ON h.Num_inspeccion = m.Num_inspeccion
  JOIN CONTRATO c                 ON c.Num_contrato = h.Num_contrato
  JOIN CONTRATISTA ct             ON ct.RUC = c.RUC
  LEFT JOIN DECLARACION_JURADA dj ON dj.Num_inspeccion = m.Num_inspeccion
  WHERE h.Estado = 'Pendiente'
  ORDER BY i.Periodo, ct.Razon_social;
END$$

-- Reporte 10: pago de CTS y gratificación en el periodo, por HES de una analista
CREATE PROCEDURE sp_rep_cts_gratificacion(IN p_periodo VARCHAR(10), IN p_num_registro VARCHAR(20))
BEGIN
  SELECT h.Num_HES, ct.Razon_social,
         MAX(CASE WHEN d.Cod_obligacion = '1.8' THEN
                  CASE WHEN d.Monto_declarado IS NULL THEN 'No aplica'
                       WHEN d.Monto_pagado >= d.Monto_declarado THEN 'Pagado'
                       ELSE 'Pago incompleto' END END) AS CTS,
         MAX(CASE WHEN d.Cod_obligacion = '1.9' THEN
                  CASE WHEN d.Monto_declarado IS NULL THEN 'No aplica'
                       WHEN d.Monto_pagado >= d.Monto_declarado THEN 'Pagado'
                       ELSE 'Pago incompleto' END END) AS Gratificacion,
         MAX(CASE WHEN d.Cod_obligacion = '1.9' THEN d.Monto_declarado END) AS Declarado,
         MAX(CASE WHEN d.Cod_obligacion = '1.9' THEN d.Monto_pagado END) AS Pagado
  FROM DECLARA d
  JOIN INSPECCION_OBLIGACIONES i ON i.Num_inspeccion = d.Num_inspeccion
  JOIN HES h                     ON h.Num_inspeccion = i.Num_inspeccion
  JOIN CONTRATO c                ON c.Num_contrato = h.Num_contrato
  JOIN CONTRATISTA ct            ON ct.RUC = c.RUC
  WHERE i.Periodo = p_periodo
    AND c.Num_registro_analista = p_num_registro
    AND d.Cod_obligacion IN ('1.8', '1.9')
  GROUP BY h.Num_HES, ct.Razon_social
  ORDER BY h.Num_HES;
END$$

-- Reporte 11: boletas sin firma en inspecciones que marcan la obligación 2.2 como cumplida
CREATE PROCEDURE sp_rep_boletas_sin_firma()
BEGIN
  SELECT i.Num_inspeccion, i.Periodo, ct.Razon_social,
         COUNT(*) AS Boletas_sin_firma,
         GROUP_CONCAT(CONCAT(t.Apellidos, ', ', t.Nombres) ORDER BY t.Apellidos SEPARATOR '; ') AS Trabajadores
  FROM VERIFICA v
  JOIN BOLETA_PAGO b             ON b.Num_inspeccion = v.Num_inspeccion
  JOIN TRABAJADOR t              ON t.DNI = b.DNI
  JOIN INSPECCION_OBLIGACIONES i ON i.Num_inspeccion = v.Num_inspeccion
  JOIN HES h                     ON h.Num_inspeccion = i.Num_inspeccion
  JOIN CONTRATO c                ON c.Num_contrato = h.Num_contrato
  JOIN CONTRATISTA ct            ON ct.RUC = c.RUC
  WHERE v.Cod_obligacion_legal = '2.2'
    AND v.Cumplimiento = 'OK'
    AND b.Firma_trabajador = 'No firmada'
  GROUP BY i.Num_inspeccion, i.Periodo, ct.Razon_social
  ORDER BY Boletas_sin_firma DESC, i.Num_inspeccion;
END$$

-- Reporte 12: HES aprobadas del periodo para el memo de facturación de una analista
CREATE PROCEDURE sp_rep_memo_facturacion(IN p_periodo VARCHAR(10), IN p_num_registro VARCHAR(20))
BEGIN
  SELECT h.Num_HES, h.Fecha_emision, c.Num_contrato, ct.Razon_social,
         cc.Nombre_centro_costo AS Centro_de_costo, h.Monto_servicio
  FROM HES h
  JOIN INSPECCION_OBLIGACIONES i ON i.Num_inspeccion = h.Num_inspeccion
  JOIN CONTRATO c                ON c.Num_contrato = h.Num_contrato
  JOIN CONTRATISTA ct            ON ct.RUC = c.RUC
  JOIN CENTRO_COSTO cc           ON cc.Cod_centro_costo = c.Cod_centro_costo
  WHERE h.Estado = 'Aprobada'
    AND i.Periodo = p_periodo
    AND c.Num_registro_analista = p_num_registro
  ORDER BY ct.Razon_social, h.Num_HES;
END$$

-- Reporte 13: monto aprobado por centro de costo en el periodo
CREATE PROCEDURE sp_rep_monto_centro_costo(IN p_periodo VARCHAR(10))
BEGIN
  SELECT cc.Cod_centro_costo, cc.Nombre_centro_costo AS Centro_de_costo,
         COUNT(*) AS HES_aprobadas,
         SUM(h.Monto_servicio) AS Monto_total
  FROM HES h
  JOIN INSPECCION_OBLIGACIONES i ON i.Num_inspeccion = h.Num_inspeccion
  JOIN CONTRATO c                ON c.Num_contrato = h.Num_contrato
  JOIN CENTRO_COSTO cc           ON cc.Cod_centro_costo = c.Cod_centro_costo
  WHERE h.Estado = 'Aprobada'
    AND i.Periodo = p_periodo
  GROUP BY cc.Cod_centro_costo, cc.Nombre_centro_costo
  ORDER BY Monto_total DESC;
END$$

DELIMITER ;

-- ----------------------------------------------------------------------------
-- VERIFICACIÓN
-- ----------------------------------------------------------------------------
SELECT COUNT(*) AS Procedimientos
FROM information_schema.ROUTINES
WHERE ROUTINE_SCHEMA = 'hes_spcc' AND ROUTINE_TYPE = 'PROCEDURE';

SELECT COUNT(*) AS Triggers
FROM information_schema.TRIGGERS
WHERE TRIGGER_SCHEMA = 'hes_spcc';
