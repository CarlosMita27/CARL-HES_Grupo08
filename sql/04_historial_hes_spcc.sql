-- ============================================================================
-- Base de datos: revisión y liberación de la HES (SPCC)
-- Cuarta Entrega: gestión de historiales (archivo de periodos cerrados)
-- Ejecutar después de los scripts de creación y de inserción de datos.
-- Política: cada año se trasladan a la base histórica las inspecciones con más de
-- 24 meses de antigüedad cuya HES ya está cerrada (no pendiente), con todos sus
-- documentos. Las tablas maestras permanecen en la base operativa.
-- ============================================================================

DROP DATABASE IF EXISTS hes_spcc_historico;
CREATE DATABASE hes_spcc_historico DEFAULT CHARACTER SET utf8mb4;

-- Tablas históricas con la misma estructura que las tablas transaccionales
CREATE TABLE IF NOT EXISTS hes_spcc_historico.INSPECCION_OBLIGACIONES LIKE hes_spcc.INSPECCION_OBLIGACIONES;
CREATE TABLE IF NOT EXISTS hes_spcc_historico.HES                     LIKE hes_spcc.HES;
CREATE TABLE IF NOT EXISTS hes_spcc_historico.OBSERVACION             LIKE hes_spcc.OBSERVACION;
CREATE TABLE IF NOT EXISTS hes_spcc_historico.REPORTE_ENTIDAD         LIKE hes_spcc.REPORTE_ENTIDAD;
CREATE TABLE IF NOT EXISTS hes_spcc_historico.BOLETA_PAGO             LIKE hes_spcc.BOLETA_PAGO;
CREATE TABLE IF NOT EXISTS hes_spcc_historico.DECLARACION_JURADA      LIKE hes_spcc.DECLARACION_JURADA;
CREATE TABLE IF NOT EXISTS hes_spcc_historico.DECLARA                 LIKE hes_spcc.DECLARA;
CREATE TABLE IF NOT EXISTS hes_spcc_historico.VERIFICA                LIKE hes_spcc.VERIFICA;
CREATE TABLE IF NOT EXISTS hes_spcc_historico.RESPALDA                LIKE hes_spcc.RESPALDA;

USE hes_spcc;

-- ----------------------------------------------------------------------------
-- Procedimiento de archivo: traslada las inspecciones anteriores al periodo
-- límite (formato aaaamm) cuya HES está cerrada, dentro de una transacción.
-- ----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_archivar_historial;

DELIMITER $$
CREATE PROCEDURE sp_archivar_historial(IN p_periodo_limite CHAR(6))
BEGIN
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    DROP TEMPORARY TABLE IF EXISTS tmp_archivo;
    RESIGNAL;
  END;

  DROP TEMPORARY TABLE IF EXISTS tmp_archivo;
  CREATE TEMPORARY TABLE tmp_archivo (Num_inspeccion CHAR(15) PRIMARY KEY);
  INSERT INTO tmp_archivo
  SELECT i.Num_inspeccion
  FROM INSPECCION_OBLIGACIONES i
  JOIN HES h ON h.Num_inspeccion = i.Num_inspeccion
  WHERE i.Periodo < p_periodo_limite
    AND h.Estado <> 'Pendiente';

  START TRANSACTION;

  -- 1. Copia a la base histórica (de las tablas referidas a las que refieren)
  INSERT INTO hes_spcc_historico.INSPECCION_OBLIGACIONES
  SELECT i.* FROM INSPECCION_OBLIGACIONES i JOIN tmp_archivo t ON t.Num_inspeccion = i.Num_inspeccion;
  INSERT INTO hes_spcc_historico.HES
  SELECT h.* FROM HES h JOIN tmp_archivo t ON t.Num_inspeccion = h.Num_inspeccion;
  INSERT INTO hes_spcc_historico.OBSERVACION
  SELECT o.* FROM OBSERVACION o JOIN HES h ON h.Num_HES = o.Num_HES JOIN tmp_archivo t ON t.Num_inspeccion = h.Num_inspeccion;
  INSERT INTO hes_spcc_historico.REPORTE_ENTIDAD
  SELECT r.* FROM REPORTE_ENTIDAD r JOIN tmp_archivo t ON t.Num_inspeccion = r.Num_inspeccion;
  INSERT INTO hes_spcc_historico.RESPALDA
  SELECT rs.* FROM RESPALDA rs JOIN REPORTE_ENTIDAD r ON r.Num_reporte = rs.Num_reporte JOIN tmp_archivo t ON t.Num_inspeccion = r.Num_inspeccion;
  INSERT INTO hes_spcc_historico.BOLETA_PAGO
  SELECT b.* FROM BOLETA_PAGO b JOIN tmp_archivo t ON t.Num_inspeccion = b.Num_inspeccion;
  INSERT INTO hes_spcc_historico.DECLARACION_JURADA
  SELECT dj.* FROM DECLARACION_JURADA dj JOIN tmp_archivo t ON t.Num_inspeccion = dj.Num_inspeccion;
  INSERT INTO hes_spcc_historico.DECLARA
  SELECT d.* FROM DECLARA d JOIN tmp_archivo t ON t.Num_inspeccion = d.Num_inspeccion;
  INSERT INTO hes_spcc_historico.VERIFICA
  SELECT v.* FROM VERIFICA v JOIN tmp_archivo t ON t.Num_inspeccion = v.Num_inspeccion;

  -- 2. Eliminación de la base operativa (de las tablas que refieren a las referidas)
  DELETE rs FROM RESPALDA rs JOIN REPORTE_ENTIDAD r ON r.Num_reporte = rs.Num_reporte JOIN tmp_archivo t ON t.Num_inspeccion = r.Num_inspeccion;
  DELETE d  FROM DECLARA d             JOIN tmp_archivo t ON t.Num_inspeccion = d.Num_inspeccion;
  DELETE v  FROM VERIFICA v            JOIN tmp_archivo t ON t.Num_inspeccion = v.Num_inspeccion;
  DELETE b  FROM BOLETA_PAGO b         JOIN tmp_archivo t ON t.Num_inspeccion = b.Num_inspeccion;
  DELETE dj FROM DECLARACION_JURADA dj JOIN tmp_archivo t ON t.Num_inspeccion = dj.Num_inspeccion;
  DELETE r  FROM REPORTE_ENTIDAD r     JOIN tmp_archivo t ON t.Num_inspeccion = r.Num_inspeccion;
  DELETE o  FROM OBSERVACION o JOIN HES h ON h.Num_HES = o.Num_HES JOIN tmp_archivo t ON t.Num_inspeccion = h.Num_inspeccion;
  DELETE h  FROM HES h                 JOIN tmp_archivo t ON t.Num_inspeccion = h.Num_inspeccion;
  DELETE i  FROM INSPECCION_OBLIGACIONES i JOIN tmp_archivo t ON t.Num_inspeccion = i.Num_inspeccion;

  COMMIT;

  SELECT COUNT(*) AS Inspecciones_archivadas FROM tmp_archivo;
  DROP TEMPORARY TABLE tmp_archivo;
END$$
DELIMITER ;

-- ----------------------------------------------------------------------------
-- Vista para consultar las HES operativas e históricas en un solo resultado
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_hes_completa AS
SELECT h.Num_HES, h.Fecha_emision, h.Estado, h.Monto_servicio, h.Num_contrato,
       i.Num_inspeccion, i.Periodo, 'Operativa' AS Origen
FROM hes_spcc.HES h
JOIN hes_spcc.INSPECCION_OBLIGACIONES i ON i.Num_inspeccion = h.Num_inspeccion
UNION ALL
SELECT h.Num_HES, h.Fecha_emision, h.Estado, h.Monto_servicio, h.Num_contrato,
       i.Num_inspeccion, i.Periodo, 'Histórica' AS Origen
FROM hes_spcc_historico.HES h
JOIN hes_spcc_historico.INSPECCION_OBLIGACIONES i ON i.Num_inspeccion = h.Num_inspeccion;

-- ----------------------------------------------------------------------------
-- Ejecución anual automática: el 4 de enero de cada año a las 02:00, después
-- del respaldo completo de fin de año. Conserva en la base operativa los 24
-- meses más recientes.
-- ----------------------------------------------------------------------------
DROP EVENT IF EXISTS ev_archivo_anual;
CREATE EVENT ev_archivo_anual
ON SCHEDULE EVERY 1 YEAR STARTS '2027-01-04 02:00:00'
DO CALL sp_archivar_historial(DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL 24 MONTH), '%Y%m'));

-- Ejemplo de ejecución manual (archiva los periodos anteriores a enero de 2025):
-- CALL sp_archivar_historial('202501');
