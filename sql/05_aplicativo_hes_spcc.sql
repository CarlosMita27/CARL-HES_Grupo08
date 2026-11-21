-- ============================================================================
-- Base de datos: revisión y liberación de la HES (SPCC)
-- Gestión de Datos e Información - UCSM. Quinta Entrega: aplicativo (avance 30 %)
-- Gestor: MySQL 8.0 con el motor InnoDB
-- Contenido: eliminación lógica, triggers que impiden el borrado físico,
--            usuario del aplicativo y procedimientos que llama el aplicativo.
-- Orden: ejecutar una sola vez, después de los scripts 01, 02 y 04.
--        Para repetirlo, volver a ejecutar 01, 02, 04 y luego este script.
-- ============================================================================

SET NAMES utf8mb4;
USE hes_spcc;

-- ----------------------------------------------------------------------------
-- ELIMINACIÓN LÓGICA: Activo = 1 (vigente) o 0 (dado de baja)
-- ----------------------------------------------------------------------------
ALTER TABLE CONTRATISTA
  ADD COLUMN Activo TINYINT(1) NOT NULL DEFAULT 1,
  ADD CONSTRAINT ck_contratista_activo CHECK (Activo IN (0, 1));

ALTER TABLE CONTRATO
  ADD COLUMN Activo TINYINT(1) NOT NULL DEFAULT 1,
  ADD CONSTRAINT ck_contrato_activo CHECK (Activo IN (0, 1));

ALTER TABLE ANALISTA
  ADD COLUMN Activo TINYINT(1) NOT NULL DEFAULT 1,
  ADD CONSTRAINT ck_analista_activo CHECK (Activo IN (0, 1));

ALTER TABLE CENTRO_COSTO
  ADD COLUMN Activo TINYINT(1) NOT NULL DEFAULT 1,
  ADD CONSTRAINT ck_centro_costo_activo CHECK (Activo IN (0, 1));

ALTER TABLE TRABAJADOR
  ADD COLUMN Activo TINYINT(1) NOT NULL DEFAULT 1,
  ADD CONSTRAINT ck_trabajador_activo CHECK (Activo IN (0, 1));

-- ----------------------------------------------------------------------------
-- TRIGGERS: impiden el borrado físico en las tablas con eliminación lógica
-- ----------------------------------------------------------------------------
DROP TRIGGER IF EXISTS tr_contratista_no_borrar;
DROP TRIGGER IF EXISTS tr_contrato_no_borrar;
DROP TRIGGER IF EXISTS tr_analista_no_borrar;
DROP TRIGGER IF EXISTS tr_centro_costo_no_borrar;
DROP TRIGGER IF EXISTS tr_trabajador_no_borrar;

DELIMITER $$

CREATE TRIGGER tr_contratista_no_borrar BEFORE DELETE ON CONTRATISTA
FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'No se permite borrar contratistas: use la eliminación lógica (Activo = 0)';
END$$

CREATE TRIGGER tr_contrato_no_borrar BEFORE DELETE ON CONTRATO
FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'No se permite borrar contratos: use la eliminación lógica (Activo = 0)';
END$$

CREATE TRIGGER tr_analista_no_borrar BEFORE DELETE ON ANALISTA
FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'No se permite borrar analistas: use la eliminación lógica (Activo = 0)';
END$$

CREATE TRIGGER tr_centro_costo_no_borrar BEFORE DELETE ON CENTRO_COSTO
FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'No se permite borrar centros de costo: use la eliminación lógica (Activo = 0)';
END$$

CREATE TRIGGER tr_trabajador_no_borrar BEFORE DELETE ON TRABAJADOR
FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'No se permite borrar trabajadores: use la eliminación lógica (Activo = 0)';
END$$

DELIMITER ;

-- ----------------------------------------------------------------------------
-- PROCEDIMIENTOS DEL APLICATIVO
-- ----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_info_conexion;
DROP PROCEDURE IF EXISTS sp_resumen_inicio;
DROP PROCEDURE IF EXISTS sp_hes_por_estado;
DROP PROCEDURE IF EXISTS sp_hes_recientes;
DROP PROCEDURE IF EXISTS sp_contratista_buscar;
DROP PROCEDURE IF EXISTS sp_periodo_listar;
DROP PROCEDURE IF EXISTS sp_hes_buscar;
DROP PROCEDURE IF EXISTS sp_hes_detalle;
DROP PROCEDURE IF EXISTS sp_hes_observaciones;
DROP PROCEDURE IF EXISTS sp_analista_listar;
DROP PROCEDURE IF EXISTS sp_rep_hes_pendientes_analista;

DELIMITER $$

-- Datos del servidor y de la base, para la prueba de conexión
CREATE PROCEDURE sp_info_conexion()
BEGIN
  SELECT VERSION() AS Version_servidor,
         DATABASE() AS Base_datos,
         USER() AS Usuario_conectado,
         NOW() AS Fecha_hora_servidor,
         (SELECT COUNT(*) FROM information_schema.TABLES
           WHERE TABLE_SCHEMA = DATABASE() AND TABLE_TYPE = 'BASE TABLE') AS Tablas,
         (SELECT COUNT(*) FROM information_schema.ROUTINES
           WHERE ROUTINE_SCHEMA = DATABASE() AND ROUTINE_TYPE = 'PROCEDURE') AS Procedimientos,
         (SELECT COUNT(*) FROM information_schema.TRIGGERS
           WHERE TRIGGER_SCHEMA = DATABASE()) AS Triggers;
END$$

-- Indicadores del panel de inicio
CREATE PROCEDURE sp_resumen_inicio()
BEGIN
  SELECT (SELECT COUNT(*) FROM CONTRATISTA WHERE Activo = 1) AS Contratistas_activos,
         (SELECT COUNT(*) FROM CONTRATO WHERE Activo = 1) AS Contratos_activos,
         (SELECT COUNT(*) FROM ANALISTA WHERE Activo = 1) AS Analistas_activos,
         (SELECT COUNT(*) FROM HES) AS Hes_registradas,
         (SELECT COUNT(*) FROM HES WHERE Estado = 'Pendiente') AS Hes_pendientes,
         (SELECT COUNT(*) FROM HES WHERE Estado = 'Aprobada') AS Hes_aprobadas,
         (SELECT COALESCE(SUM(Monto_servicio), 0) FROM HES WHERE Estado = 'Aprobada') AS Monto_aprobado,
         (SELECT COUNT(*) FROM OBSERVACION) AS Observaciones;
END$$

-- Cantidad y monto de HES por estado
CREATE PROCEDURE sp_hes_por_estado()
BEGIN
  SELECT Estado, COUNT(*) AS Cantidad, SUM(Monto_servicio) AS Monto
  FROM HES
  GROUP BY Estado
  ORDER BY Estado;
END$$

-- Últimas HES emitidas
CREATE PROCEDURE sp_hes_recientes(IN p_cantidad TINYINT UNSIGNED)
BEGIN
  SELECT h.Num_HES, h.Fecha_emision, h.Estado, h.Monto_servicio, ct.Razon_social
  FROM HES h
  JOIN CONTRATO c     ON c.Num_contrato = h.Num_contrato
  JOIN CONTRATISTA ct ON ct.RUC = c.RUC
  ORDER BY h.Fecha_emision DESC, h.Num_HES DESC
  LIMIT p_cantidad;
END$$

-- Búsqueda de contratistas por RUC o razón social, con teléfonos, contratos y HES pendientes
CREATE PROCEDURE sp_contratista_buscar(IN p_texto VARCHAR(100), IN p_incluir_inactivos TINYINT)
BEGIN
  SELECT ct.RUC, ct.Razon_social,
         COALESCE(t.Telefonos, '') AS Telefonos,
         COALESCE(c.Contratos, 0) AS Contratos,
         COALESCE(p.Hes_pendientes, 0) AS Hes_pendientes,
         ct.Activo
  FROM CONTRATISTA ct
  LEFT JOIN (SELECT RUC, GROUP_CONCAT(Telefono ORDER BY Telefono SEPARATOR ', ') AS Telefonos
             FROM TELEFONO_CONTRATISTA GROUP BY RUC) t ON t.RUC = ct.RUC
  LEFT JOIN (SELECT RUC, COUNT(*) AS Contratos
             FROM CONTRATO WHERE Activo = 1 GROUP BY RUC) c ON c.RUC = ct.RUC
  LEFT JOIN (SELECT co.RUC, COUNT(*) AS Hes_pendientes
             FROM HES h JOIN CONTRATO co ON co.Num_contrato = h.Num_contrato
             WHERE h.Estado = 'Pendiente' GROUP BY co.RUC) p ON p.RUC = ct.RUC
  WHERE (p_texto IS NULL OR p_texto = ''
         OR ct.RUC LIKE CONCAT('%', p_texto, '%')
         OR ct.Razon_social LIKE CONCAT('%', p_texto, '%'))
    AND (p_incluir_inactivos = 1 OR ct.Activo = 1)
  ORDER BY ct.Razon_social;
END$$

-- Periodos con inspecciones registradas, para los filtros
CREATE PROCEDURE sp_periodo_listar()
BEGIN
  SELECT DISTINCT Periodo
  FROM INSPECCION_OBLIGACIONES
  ORDER BY Periodo DESC;
END$$

-- Búsqueda de HES por texto, estado y periodo (los filtros vacíos no se aplican)
CREATE PROCEDURE sp_hes_buscar(IN p_texto VARCHAR(100), IN p_estado VARCHAR(10), IN p_periodo CHAR(6))
BEGIN
  SELECT h.Num_HES, h.Fecha_emision, i.Periodo, ct.Razon_social, h.Num_contrato,
         CONCAT(SUBSTRING_INDEX(a.Nombres, ' ', 1), ' ', SUBSTRING_INDEX(a.Apellidos, ' ', 1)) AS Analista,
         h.Monto_servicio, h.Estado
  FROM HES h
  JOIN INSPECCION_OBLIGACIONES i ON i.Num_inspeccion = h.Num_inspeccion
  JOIN CONTRATO c                ON c.Num_contrato = h.Num_contrato
  JOIN CONTRATISTA ct            ON ct.RUC = c.RUC
  JOIN ANALISTA a                ON a.Num_registro = c.Num_registro_analista
  WHERE (p_texto IS NULL OR p_texto = ''
         OR h.Num_HES LIKE CONCAT('%', p_texto, '%')
         OR h.Num_contrato LIKE CONCAT('%', p_texto, '%')
         OR ct.RUC LIKE CONCAT('%', p_texto, '%')
         OR ct.Razon_social LIKE CONCAT('%', p_texto, '%'))
    AND (p_estado IS NULL OR p_estado = '' OR h.Estado = p_estado)
    AND (p_periodo IS NULL OR p_periodo = '' OR i.Periodo = p_periodo)
  ORDER BY h.Fecha_emision DESC, h.Num_HES DESC;
END$$

-- Detalle de una HES con su contrato, contratista, analista e inspección
CREATE PROCEDURE sp_hes_detalle(IN p_num_hes CHAR(6))
BEGIN
  SELECT h.Num_HES, h.Fecha_emision, h.Estado, h.Monto_servicio,
         CASE WHEN h.Estado = 'Pendiente' THEN DATEDIFF(CURDATE(), h.Fecha_emision) END AS Dias_en_espera,
         c.Num_contrato, c.Monto_total, cc.Cod_centro_costo, cc.Nombre_centro_costo,
         ct.RUC, ct.Razon_social,
         (SELECT GROUP_CONCAT(t.Telefono ORDER BY t.Telefono SEPARATOR ', ')
            FROM TELEFONO_CONTRATISTA t WHERE t.RUC = ct.RUC) AS Telefonos,
         a.Num_registro, CONCAT(a.Nombres, ' ', a.Apellidos) AS Analista, cg.Nombre_cargo AS Cargo,
         i.Num_inspeccion, i.Periodo, i.Firma_contratista,
         (SELECT COUNT(*) FROM REPORTE_ENTIDAD r WHERE r.Num_inspeccion = i.Num_inspeccion) AS Reportes,
         (SELECT COUNT(*) FROM BOLETA_PAGO b WHERE b.Num_inspeccion = i.Num_inspeccion) AS Boletas,
         (SELECT COUNT(*) FROM BOLETA_PAGO b
           WHERE b.Num_inspeccion = i.Num_inspeccion AND b.Firma_trabajador = 'No firmada') AS Boletas_sin_firma,
         (SELECT COUNT(*) FROM DECLARACION_JURADA d WHERE d.Num_inspeccion = i.Num_inspeccion) AS Declaraciones
  FROM HES h
  JOIN CONTRATO c                ON c.Num_contrato = h.Num_contrato
  JOIN CENTRO_COSTO cc           ON cc.Cod_centro_costo = c.Cod_centro_costo
  JOIN CONTRATISTA ct            ON ct.RUC = c.RUC
  JOIN ANALISTA a                ON a.Num_registro = c.Num_registro_analista
  JOIN CARGO cg                  ON cg.Cod_cargo = a.Cod_cargo
  JOIN INSPECCION_OBLIGACIONES i ON i.Num_inspeccion = h.Num_inspeccion
  WHERE h.Num_HES = p_num_hes;
END$$

-- Observaciones de una HES, en orden
CREATE PROCEDURE sp_hes_observaciones(IN p_num_hes CHAR(6))
BEGIN
  SELECT Num_observacion, Fecha_observacion, Comentario
  FROM OBSERVACION
  WHERE Num_HES = p_num_hes
  ORDER BY Num_observacion;
END$$

-- Analistas con su cargo y contratos a cargo
CREATE PROCEDURE sp_analista_listar(IN p_incluir_inactivos TINYINT)
BEGIN
  SELECT a.Num_registro, a.Apellidos, a.Nombres, cg.Nombre_cargo AS Cargo,
         COUNT(c.Num_contrato) AS Contratos, a.Activo
  FROM ANALISTA a
  JOIN CARGO cg        ON cg.Cod_cargo = a.Cod_cargo
  LEFT JOIN CONTRATO c ON c.Num_registro_analista = a.Num_registro AND c.Activo = 1
  WHERE p_incluir_inactivos = 1 OR a.Activo = 1
  GROUP BY a.Num_registro, a.Apellidos, a.Nombres, cg.Nombre_cargo, a.Activo
  ORDER BY a.Apellidos, a.Nombres;
END$$

-- Reporte 1: HES pendientes de una analista, de la más antigua a la más reciente
CREATE PROCEDURE sp_rep_hes_pendientes_analista(IN p_num_registro CHAR(6))
BEGIN
  SELECT h.Num_HES, h.Fecha_emision,
         DATEDIFF(CURDATE(), h.Fecha_emision) AS Dias_en_espera,
         c.Num_contrato, ct.Razon_social, h.Monto_servicio
  FROM HES h
  JOIN CONTRATO c     ON c.Num_contrato = h.Num_contrato
  JOIN CONTRATISTA ct ON ct.RUC = c.RUC
  WHERE h.Estado = 'Pendiente'
    AND c.Num_registro_analista = p_num_registro
  ORDER BY h.Fecha_emision;
END$$

DELIMITER ;

-- ----------------------------------------------------------------------------
-- USUARIO DEL APLICATIVO: solo puede ejecutar procedimientos de hes_spcc
-- ----------------------------------------------------------------------------
CREATE USER IF NOT EXISTS 'app_hes'@'localhost' IDENTIFIED BY 'HesApp2026#';
GRANT EXECUTE ON hes_spcc.* TO 'app_hes'@'localhost';

-- ----------------------------------------------------------------------------
-- VERIFICACIÓN
-- ----------------------------------------------------------------------------
SELECT ROUTINE_NAME AS Procedimiento
FROM information_schema.ROUTINES
WHERE ROUTINE_SCHEMA = 'hes_spcc' AND ROUTINE_TYPE = 'PROCEDURE'
ORDER BY ROUTINE_NAME;

SHOW GRANTS FOR 'app_hes'@'localhost';
