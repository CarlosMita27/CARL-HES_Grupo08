-- ============================================================================
-- Base de datos: revisión y liberación de la HES (SPCC)
-- Gestión de Datos e Información - UCSM. Quinta Entrega: aplicativo (avance 70 %)
-- Gestor: MySQL 8.0 con el motor InnoDB
-- Contenido: triggers y procedimientos del registro, la edición y la
--            eliminación lógica (CRUD) que usa el aplicativo.
-- Orden: ejecutar después de 01, 02, 04 y 05 (los triggers se crean después
--        de cargar los datos). Este script se puede volver a ejecutar.
-- ============================================================================

SET NAMES utf8mb4;
USE hes_spcc;

-- ----------------------------------------------------------------------------
-- TRIGGERS: reglas que la base hace cumplir en cada inserción o actualización
-- ----------------------------------------------------------------------------
DROP TRIGGER IF EXISTS tr_contratista_baja_bu;
DROP TRIGGER IF EXISTS tr_contrato_validar_bi;
DROP TRIGGER IF EXISTS tr_contrato_validar_bu;
DROP TRIGGER IF EXISTS tr_analista_baja_bu;
DROP TRIGGER IF EXISTS tr_centro_costo_baja_bu;
DROP TRIGGER IF EXISTS tr_hes_contrato_bi;
DROP TRIGGER IF EXISTS tr_hes_solo_pendiente_bu;
DROP TRIGGER IF EXISTS tr_observacion_hes_pendiente_bi;
DROP TRIGGER IF EXISTS tr_observacion_hes_pendiente_bu;

DELIMITER $$

-- Una contratista con contratos vigentes no puede darse de baja
CREATE TRIGGER tr_contratista_baja_bu BEFORE UPDATE ON CONTRATISTA
FOR EACH ROW
BEGIN
  IF OLD.Activo = 1 AND NEW.Activo = 0
     AND EXISTS (SELECT 1 FROM CONTRATO WHERE RUC = NEW.RUC AND Activo = 1) THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'No se puede dar de baja a la contratista: tiene contratos vigentes';
  END IF;
END$$

-- Un contrato nuevo exige contratista, analista y centro de costo vigentes
CREATE TRIGGER tr_contrato_validar_bi BEFORE INSERT ON CONTRATO
FOR EACH ROW
BEGIN
  IF NOT EXISTS (SELECT 1 FROM CONTRATISTA WHERE RUC = NEW.RUC AND Activo = 1) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La contratista no existe o está dada de baja';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM ANALISTA WHERE Num_registro = NEW.Num_registro_analista AND Activo = 1) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La analista no existe o está dada de baja';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM CENTRO_COSTO WHERE Cod_centro_costo = NEW.Cod_centro_costo AND Activo = 1) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El centro de costo no existe o está dado de baja';
  END IF;
END$$

-- Un contrato con HES pendientes no puede darse de baja;
-- al editarlo o reactivarlo, sus datos relacionados deben estar vigentes
CREATE TRIGGER tr_contrato_validar_bu BEFORE UPDATE ON CONTRATO
FOR EACH ROW
BEGIN
  IF OLD.Activo = 1 AND NEW.Activo = 0
     AND EXISTS (SELECT 1 FROM HES WHERE Num_contrato = NEW.Num_contrato AND Estado = 'Pendiente') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No se puede dar de baja el contrato: tiene HES pendientes';
  END IF;
  IF NEW.Activo = 1 THEN
    IF NOT EXISTS (SELECT 1 FROM CONTRATISTA WHERE RUC = NEW.RUC AND Activo = 1) THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La contratista del contrato está dada de baja';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM ANALISTA WHERE Num_registro = NEW.Num_registro_analista AND Activo = 1) THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La analista no existe o está dada de baja';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM CENTRO_COSTO WHERE Cod_centro_costo = NEW.Cod_centro_costo AND Activo = 1) THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El centro de costo no existe o está dado de baja';
    END IF;
  END IF;
END$$

-- Una analista con contratos vigentes a su cargo no puede darse de baja
CREATE TRIGGER tr_analista_baja_bu BEFORE UPDATE ON ANALISTA
FOR EACH ROW
BEGIN
  IF OLD.Activo = 1 AND NEW.Activo = 0
     AND EXISTS (SELECT 1 FROM CONTRATO WHERE Num_registro_analista = NEW.Num_registro AND Activo = 1) THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'No se puede dar de baja a la analista: tiene contratos vigentes a su cargo';
  END IF;
END$$

-- Un centro de costo con contratos vigentes no puede darse de baja
CREATE TRIGGER tr_centro_costo_baja_bu BEFORE UPDATE ON CENTRO_COSTO
FOR EACH ROW
BEGIN
  IF OLD.Activo = 1 AND NEW.Activo = 0
     AND EXISTS (SELECT 1 FROM CONTRATO WHERE Cod_centro_costo = NEW.Cod_centro_costo AND Activo = 1) THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'No se puede dar de baja el centro de costo: tiene contratos vigentes';
  END IF;
END$$

-- Solo se emiten HES para contratos vigentes
CREATE TRIGGER tr_hes_contrato_bi BEFORE INSERT ON HES
FOR EACH ROW
BEGIN
  IF NOT EXISTS (SELECT 1 FROM CONTRATO WHERE Num_contrato = NEW.Num_contrato AND Activo = 1) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El contrato no existe o está dado de baja';
  END IF;
END$$

-- Una HES solo se modifica mientras está pendiente
CREATE TRIGGER tr_hes_solo_pendiente_bu BEFORE UPDATE ON HES
FOR EACH ROW
BEGIN
  DECLARE v_mensaje VARCHAR(128);
  IF OLD.Estado <> 'Pendiente' THEN
    SET v_mensaje = CONCAT('La HES ', OLD.Num_HES, ' está ', LOWER(OLD.Estado), ' y ya no se puede modificar');
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_mensaje;
  END IF;
END$$

-- Las observaciones solo se registran o editan en HES pendientes
CREATE TRIGGER tr_observacion_hes_pendiente_bi BEFORE INSERT ON OBSERVACION
FOR EACH ROW
BEGIN
  IF NOT EXISTS (SELECT 1 FROM HES WHERE Num_HES = NEW.Num_HES AND Estado = 'Pendiente') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Solo se pueden registrar observaciones en una HES pendiente';
  END IF;
END$$

CREATE TRIGGER tr_observacion_hes_pendiente_bu BEFORE UPDATE ON OBSERVACION
FOR EACH ROW
BEGIN
  IF NOT EXISTS (SELECT 1 FROM HES WHERE Num_HES = NEW.Num_HES AND Estado = 'Pendiente') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Solo se pueden editar observaciones de una HES pendiente';
  END IF;
END$$

DELIMITER ;

-- ----------------------------------------------------------------------------
-- PROCEDIMIENTOS DEL CRUD
-- ----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_contratista_obtener;
DROP PROCEDURE IF EXISTS sp_telefono_reemplazar;
DROP PROCEDURE IF EXISTS sp_contratista_insertar;
DROP PROCEDURE IF EXISTS sp_contratista_actualizar;
DROP PROCEDURE IF EXISTS sp_contratista_eliminar;
DROP PROCEDURE IF EXISTS sp_contratista_reactivar;
DROP PROCEDURE IF EXISTS sp_contrato_buscar;
DROP PROCEDURE IF EXISTS sp_contrato_obtener;
DROP PROCEDURE IF EXISTS sp_contrato_insertar;
DROP PROCEDURE IF EXISTS sp_contrato_actualizar;
DROP PROCEDURE IF EXISTS sp_contrato_eliminar;
DROP PROCEDURE IF EXISTS sp_contrato_reactivar;
DROP PROCEDURE IF EXISTS sp_cargo_listar;
DROP PROCEDURE IF EXISTS sp_analista_obtener;
DROP PROCEDURE IF EXISTS sp_analista_insertar;
DROP PROCEDURE IF EXISTS sp_analista_actualizar;
DROP PROCEDURE IF EXISTS sp_analista_eliminar;
DROP PROCEDURE IF EXISTS sp_analista_reactivar;
DROP PROCEDURE IF EXISTS sp_centro_costo_listar;
DROP PROCEDURE IF EXISTS sp_centro_costo_obtener;
DROP PROCEDURE IF EXISTS sp_centro_costo_insertar;
DROP PROCEDURE IF EXISTS sp_centro_costo_actualizar;
DROP PROCEDURE IF EXISTS sp_centro_costo_eliminar;
DROP PROCEDURE IF EXISTS sp_centro_costo_reactivar;
DROP PROCEDURE IF EXISTS sp_hes_siguiente_numero;
DROP PROCEDURE IF EXISTS sp_hes_registrar;
DROP PROCEDURE IF EXISTS sp_hes_actualizar;
DROP PROCEDURE IF EXISTS sp_hes_cambiar_estado;
DROP PROCEDURE IF EXISTS sp_hes_anular;
DROP PROCEDURE IF EXISTS sp_observacion_obtener;
DROP PROCEDURE IF EXISTS sp_observacion_registrar;
DROP PROCEDURE IF EXISTS sp_observacion_actualizar;

DELIMITER $$

-- ---------------------------------------------------------------- CONTRATISTA

-- Datos de una contratista para el formulario de edición
CREATE PROCEDURE sp_contratista_obtener(IN p_ruc VARCHAR(20))
BEGIN
  SELECT ct.RUC, ct.Razon_social, ct.Activo,
         (SELECT GROUP_CONCAT(t.Telefono ORDER BY t.Telefono SEPARATOR ',')
            FROM TELEFONO_CONTRATISTA t WHERE t.RUC = ct.RUC) AS Telefonos
  FROM CONTRATISTA ct
  WHERE ct.RUC = p_ruc;
END$$

-- Reemplaza los teléfonos de una contratista (hasta tres; los vacíos y repetidos se omiten)
CREATE PROCEDURE sp_telefono_reemplazar(IN p_ruc VARCHAR(20), IN p_telefono1 VARCHAR(20),
                                        IN p_telefono2 VARCHAR(20), IN p_telefono3 VARCHAR(20))
BEGIN
  DECLARE v_t1 VARCHAR(20) DEFAULT NULLIF(TRIM(p_telefono1), '');
  DECLARE v_t2 VARCHAR(20) DEFAULT NULLIF(TRIM(p_telefono2), '');
  DECLARE v_t3 VARCHAR(20) DEFAULT NULLIF(TRIM(p_telefono3), '');

  DELETE FROM TELEFONO_CONTRATISTA WHERE RUC = p_ruc;
  IF v_t1 IS NOT NULL THEN
    INSERT INTO TELEFONO_CONTRATISTA (RUC, Telefono) VALUES (p_ruc, v_t1);
  END IF;
  IF v_t2 IS NOT NULL AND v_t2 <> COALESCE(v_t1, '') THEN
    INSERT INTO TELEFONO_CONTRATISTA (RUC, Telefono) VALUES (p_ruc, v_t2);
  END IF;
  IF v_t3 IS NOT NULL AND v_t3 NOT IN (COALESCE(v_t1, ''), COALESCE(v_t2, '')) THEN
    INSERT INTO TELEFONO_CONTRATISTA (RUC, Telefono) VALUES (p_ruc, v_t3);
  END IF;
END$$

-- Registra una contratista con sus teléfonos, en una sola transacción
CREATE PROCEDURE sp_contratista_insertar(IN p_ruc VARCHAR(20), IN p_razon_social VARCHAR(150),
                                         IN p_telefono1 VARCHAR(20), IN p_telefono2 VARCHAR(20),
                                         IN p_telefono3 VARCHAR(20))
BEGIN
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  IF NULLIF(TRIM(p_razon_social), '') IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La razón social es obligatoria';
  END IF;
  START TRANSACTION;
  INSERT INTO CONTRATISTA (RUC, Razon_social) VALUES (TRIM(p_ruc), TRIM(p_razon_social));
  CALL sp_telefono_reemplazar(TRIM(p_ruc), p_telefono1, p_telefono2, p_telefono3);
  COMMIT;
END$$

-- Actualiza la razón social y los teléfonos de una contratista
CREATE PROCEDURE sp_contratista_actualizar(IN p_ruc VARCHAR(20), IN p_razon_social VARCHAR(150),
                                           IN p_telefono1 VARCHAR(20), IN p_telefono2 VARCHAR(20),
                                           IN p_telefono3 VARCHAR(20))
BEGIN
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  IF NOT EXISTS (SELECT 1 FROM CONTRATISTA WHERE RUC = p_ruc) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La contratista no existe';
  END IF;
  IF NULLIF(TRIM(p_razon_social), '') IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La razón social es obligatoria';
  END IF;
  START TRANSACTION;
  UPDATE CONTRATISTA SET Razon_social = TRIM(p_razon_social) WHERE RUC = p_ruc;
  CALL sp_telefono_reemplazar(p_ruc, p_telefono1, p_telefono2, p_telefono3);
  COMMIT;
END$$

-- Eliminación lógica: la contratista queda con Activo = 0
CREATE PROCEDURE sp_contratista_eliminar(IN p_ruc VARCHAR(20))
BEGIN
  IF NOT EXISTS (SELECT 1 FROM CONTRATISTA WHERE RUC = p_ruc) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La contratista no existe';
  END IF;
  UPDATE CONTRATISTA SET Activo = 0 WHERE RUC = p_ruc;
END$$

CREATE PROCEDURE sp_contratista_reactivar(IN p_ruc VARCHAR(20))
BEGIN
  IF NOT EXISTS (SELECT 1 FROM CONTRATISTA WHERE RUC = p_ruc) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La contratista no existe';
  END IF;
  UPDATE CONTRATISTA SET Activo = 1 WHERE RUC = p_ruc;
END$$

-- ------------------------------------------------------------------- CONTRATO

-- Búsqueda de contratos con su contratista, centro de costo, analista y HES
CREATE PROCEDURE sp_contrato_buscar(IN p_texto VARCHAR(100), IN p_incluir_inactivos TINYINT)
BEGIN
  SELECT c.Num_contrato, c.Monto_total, ct.Razon_social, c.RUC,
         c.Cod_centro_costo, cc.Nombre_centro_costo,
         CONCAT(SUBSTRING_INDEX(a.Nombres, ' ', 1), ' ', SUBSTRING_INDEX(a.Apellidos, ' ', 1)) AS Analista,
         COALESCE(h.Hes_total, 0) AS Hes_total,
         COALESCE(h.Hes_pendientes, 0) AS Hes_pendientes,
         COALESCE(h.Monto_aprobado, 0) AS Monto_aprobado,
         c.Activo
  FROM CONTRATO c
  JOIN CONTRATISTA ct  ON ct.RUC = c.RUC
  JOIN CENTRO_COSTO cc ON cc.Cod_centro_costo = c.Cod_centro_costo
  JOIN ANALISTA a      ON a.Num_registro = c.Num_registro_analista
  LEFT JOIN (SELECT Num_contrato, COUNT(*) AS Hes_total,
                    SUM(Estado = 'Pendiente') AS Hes_pendientes,
                    SUM(CASE WHEN Estado = 'Aprobada' THEN Monto_servicio ELSE 0 END) AS Monto_aprobado
             FROM HES GROUP BY Num_contrato) h ON h.Num_contrato = c.Num_contrato
  WHERE (p_texto IS NULL OR p_texto = ''
         OR c.Num_contrato LIKE CONCAT('%', p_texto, '%')
         OR ct.RUC LIKE CONCAT('%', p_texto, '%')
         OR ct.Razon_social LIKE CONCAT('%', p_texto, '%'))
    AND (p_incluir_inactivos = 1 OR c.Activo = 1)
  ORDER BY c.Num_contrato;
END$$

-- Datos de un contrato para el formulario de edición
CREATE PROCEDURE sp_contrato_obtener(IN p_num_contrato VARCHAR(20))
BEGIN
  SELECT c.Num_contrato, c.Monto_total, c.RUC, ct.Razon_social,
         c.Cod_centro_costo, c.Num_registro_analista, c.Activo
  FROM CONTRATO c
  JOIN CONTRATISTA ct ON ct.RUC = c.RUC
  WHERE c.Num_contrato = p_num_contrato;
END$$

CREATE PROCEDURE sp_contrato_insertar(IN p_num_contrato VARCHAR(20), IN p_monto_total DECIMAL(13,2),
                                      IN p_ruc VARCHAR(20), IN p_cod_centro_costo VARCHAR(20),
                                      IN p_num_registro VARCHAR(20))
BEGIN
  INSERT INTO CONTRATO (Num_contrato, Monto_total, RUC, Cod_centro_costo, Num_registro_analista)
  VALUES (UPPER(TRIM(p_num_contrato)), p_monto_total, p_ruc, p_cod_centro_costo, p_num_registro);
END$$

-- El monto total no puede quedar por debajo de lo ya aprobado en HES
CREATE PROCEDURE sp_contrato_actualizar(IN p_num_contrato VARCHAR(20), IN p_monto_total DECIMAL(13,2),
                                        IN p_cod_centro_costo VARCHAR(20), IN p_num_registro VARCHAR(20))
BEGIN
  DECLARE v_aprobado DECIMAL(13,2);
  IF NOT EXISTS (SELECT 1 FROM CONTRATO WHERE Num_contrato = p_num_contrato) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El contrato no existe';
  END IF;
  SELECT COALESCE(SUM(Monto_servicio), 0) INTO v_aprobado
  FROM HES WHERE Num_contrato = p_num_contrato AND Estado = 'Aprobada';
  IF p_monto_total < v_aprobado THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'El monto total no puede ser menor que el monto ya aprobado en HES del contrato';
  END IF;
  UPDATE CONTRATO
  SET Monto_total = p_monto_total,
      Cod_centro_costo = p_cod_centro_costo,
      Num_registro_analista = p_num_registro
  WHERE Num_contrato = p_num_contrato;
END$$

CREATE PROCEDURE sp_contrato_eliminar(IN p_num_contrato VARCHAR(20))
BEGIN
  IF NOT EXISTS (SELECT 1 FROM CONTRATO WHERE Num_contrato = p_num_contrato) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El contrato no existe';
  END IF;
  UPDATE CONTRATO SET Activo = 0 WHERE Num_contrato = p_num_contrato;
END$$

CREATE PROCEDURE sp_contrato_reactivar(IN p_num_contrato VARCHAR(20))
BEGIN
  IF NOT EXISTS (SELECT 1 FROM CONTRATO WHERE Num_contrato = p_num_contrato) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El contrato no existe';
  END IF;
  UPDATE CONTRATO SET Activo = 1 WHERE Num_contrato = p_num_contrato;
END$$

-- ------------------------------------------------------------------- ANALISTA

CREATE PROCEDURE sp_cargo_listar()
BEGIN
  SELECT Cod_cargo, Nombre_cargo FROM CARGO ORDER BY Nombre_cargo;
END$$

CREATE PROCEDURE sp_analista_obtener(IN p_num_registro VARCHAR(20))
BEGIN
  SELECT Num_registro, Apellidos, Nombres, Cod_cargo, Activo
  FROM ANALISTA
  WHERE Num_registro = p_num_registro;
END$$

CREATE PROCEDURE sp_analista_insertar(IN p_num_registro VARCHAR(20), IN p_apellidos VARCHAR(100),
                                      IN p_nombres VARCHAR(100), IN p_cod_cargo SMALLINT UNSIGNED)
BEGIN
  IF NULLIF(TRIM(p_apellidos), '') IS NULL OR NULLIF(TRIM(p_nombres), '') IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Los apellidos y los nombres son obligatorios';
  END IF;
  INSERT INTO ANALISTA (Num_registro, Apellidos, Nombres, Cod_cargo)
  VALUES (TRIM(p_num_registro), TRIM(p_apellidos), TRIM(p_nombres), p_cod_cargo);
END$$

CREATE PROCEDURE sp_analista_actualizar(IN p_num_registro VARCHAR(20), IN p_apellidos VARCHAR(100),
                                        IN p_nombres VARCHAR(100), IN p_cod_cargo SMALLINT UNSIGNED)
BEGIN
  IF NOT EXISTS (SELECT 1 FROM ANALISTA WHERE Num_registro = p_num_registro) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La analista no existe';
  END IF;
  IF NULLIF(TRIM(p_apellidos), '') IS NULL OR NULLIF(TRIM(p_nombres), '') IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Los apellidos y los nombres son obligatorios';
  END IF;
  UPDATE ANALISTA
  SET Apellidos = TRIM(p_apellidos), Nombres = TRIM(p_nombres), Cod_cargo = p_cod_cargo
  WHERE Num_registro = p_num_registro;
END$$

CREATE PROCEDURE sp_analista_eliminar(IN p_num_registro VARCHAR(20))
BEGIN
  IF NOT EXISTS (SELECT 1 FROM ANALISTA WHERE Num_registro = p_num_registro) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La analista no existe';
  END IF;
  UPDATE ANALISTA SET Activo = 0 WHERE Num_registro = p_num_registro;
END$$

CREATE PROCEDURE sp_analista_reactivar(IN p_num_registro VARCHAR(20))
BEGIN
  IF NOT EXISTS (SELECT 1 FROM ANALISTA WHERE Num_registro = p_num_registro) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La analista no existe';
  END IF;
  UPDATE ANALISTA SET Activo = 1 WHERE Num_registro = p_num_registro;
END$$

-- -------------------------------------------------------------- CENTRO_COSTO

CREATE PROCEDURE sp_centro_costo_listar(IN p_incluir_inactivos TINYINT)
BEGIN
  SELECT cc.Cod_centro_costo, cc.Nombre_centro_costo,
         COUNT(c.Num_contrato) AS Contratos, cc.Activo
  FROM CENTRO_COSTO cc
  LEFT JOIN CONTRATO c ON c.Cod_centro_costo = cc.Cod_centro_costo AND c.Activo = 1
  WHERE p_incluir_inactivos = 1 OR cc.Activo = 1
  GROUP BY cc.Cod_centro_costo, cc.Nombre_centro_costo, cc.Activo
  ORDER BY cc.Cod_centro_costo;
END$$

CREATE PROCEDURE sp_centro_costo_obtener(IN p_cod_centro_costo VARCHAR(20))
BEGIN
  SELECT Cod_centro_costo, Nombre_centro_costo, Activo
  FROM CENTRO_COSTO
  WHERE Cod_centro_costo = p_cod_centro_costo;
END$$

CREATE PROCEDURE sp_centro_costo_insertar(IN p_cod_centro_costo VARCHAR(20), IN p_nombre VARCHAR(120))
BEGIN
  IF NULLIF(TRIM(p_nombre), '') IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El nombre del centro de costo es obligatorio';
  END IF;
  INSERT INTO CENTRO_COSTO (Cod_centro_costo, Nombre_centro_costo)
  VALUES (UPPER(TRIM(p_cod_centro_costo)), TRIM(p_nombre));
END$$

CREATE PROCEDURE sp_centro_costo_actualizar(IN p_cod_centro_costo VARCHAR(20), IN p_nombre VARCHAR(120))
BEGIN
  IF NOT EXISTS (SELECT 1 FROM CENTRO_COSTO WHERE Cod_centro_costo = p_cod_centro_costo) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El centro de costo no existe';
  END IF;
  IF NULLIF(TRIM(p_nombre), '') IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El nombre del centro de costo es obligatorio';
  END IF;
  UPDATE CENTRO_COSTO SET Nombre_centro_costo = TRIM(p_nombre)
  WHERE Cod_centro_costo = p_cod_centro_costo;
END$$

CREATE PROCEDURE sp_centro_costo_eliminar(IN p_cod_centro_costo VARCHAR(20))
BEGIN
  IF NOT EXISTS (SELECT 1 FROM CENTRO_COSTO WHERE Cod_centro_costo = p_cod_centro_costo) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El centro de costo no existe';
  END IF;
  UPDATE CENTRO_COSTO SET Activo = 0 WHERE Cod_centro_costo = p_cod_centro_costo;
END$$

CREATE PROCEDURE sp_centro_costo_reactivar(IN p_cod_centro_costo VARCHAR(20))
BEGIN
  IF NOT EXISTS (SELECT 1 FROM CENTRO_COSTO WHERE Cod_centro_costo = p_cod_centro_costo) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El centro de costo no existe';
  END IF;
  UPDATE CENTRO_COSTO SET Activo = 1 WHERE Cod_centro_costo = p_cod_centro_costo;
END$$

-- ------------------------------------------------------------------------ HES

-- Número sugerido para la siguiente HES
CREATE PROCEDURE sp_hes_siguiente_numero()
BEGIN
  SELECT LPAD(COALESCE(MAX(CAST(Num_HES AS UNSIGNED)), 0) + 1, 6, '0') AS Num_HES FROM HES;
END$$

-- Registra una HES pendiente junto con su inspección de obligaciones del periodo.
-- El número de inspección se genera con el correlativo del periodo: INS-aaaa-mm-nnn
CREATE PROCEDURE sp_hes_registrar(IN p_num_hes VARCHAR(20), IN p_fecha_emision DATE,
                                  IN p_monto DECIMAL(13,2), IN p_num_contrato VARCHAR(20),
                                  IN p_periodo VARCHAR(10), IN p_firma VARCHAR(20))
BEGIN
  DECLARE v_correlativo INT;
  DECLARE v_num_inspeccion VARCHAR(20);
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  IF p_fecha_emision < STR_TO_DATE(CONCAT(p_periodo, '01'), '%Y%m%d') THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'La fecha de emisión no puede ser anterior al periodo de la inspección';
  END IF;

  START TRANSACTION;
  SELECT COALESCE(MAX(CAST(RIGHT(Num_inspeccion, 3) AS UNSIGNED)), 0) + 1 INTO v_correlativo
  FROM INSPECCION_OBLIGACIONES
  WHERE Periodo = p_periodo;
  SET v_num_inspeccion = CONCAT('INS-', LEFT(p_periodo, 4), '-', SUBSTRING(p_periodo, 5, 2), '-',
                                LPAD(v_correlativo, 3, '0'));

  INSERT INTO INSPECCION_OBLIGACIONES (Num_inspeccion, Periodo, Firma_contratista)
  VALUES (v_num_inspeccion, p_periodo, p_firma);
  INSERT INTO HES (Num_HES, Fecha_emision, Estado, Monto_servicio, Num_inspeccion, Num_contrato)
  VALUES (TRIM(p_num_hes), p_fecha_emision, 'Pendiente', p_monto, v_num_inspeccion, p_num_contrato);
  COMMIT;

  SELECT TRIM(p_num_hes) AS Num_HES, v_num_inspeccion AS Num_inspeccion;
END$$

-- Corrige la fecha de emisión y el monto de una HES pendiente
CREATE PROCEDURE sp_hes_actualizar(IN p_num_hes VARCHAR(20), IN p_fecha_emision DATE, IN p_monto DECIMAL(13,2))
BEGIN
  DECLARE v_periodo CHAR(6);
  SELECT i.Periodo INTO v_periodo
  FROM HES h JOIN INSPECCION_OBLIGACIONES i ON i.Num_inspeccion = h.Num_inspeccion
  WHERE h.Num_HES = p_num_hes;
  IF v_periodo IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La HES no existe';
  END IF;
  IF p_fecha_emision < STR_TO_DATE(CONCAT(v_periodo, '01'), '%Y%m%d') THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'La fecha de emisión no puede ser anterior al periodo de la inspección';
  END IF;
  UPDATE HES SET Fecha_emision = p_fecha_emision, Monto_servicio = p_monto WHERE Num_HES = p_num_hes;
END$$

-- Aprueba, rechaza o retira una HES pendiente.
-- Para aprobarla, el formato de la inspección debe estar firmado por la contratista
CREATE PROCEDURE sp_hes_cambiar_estado(IN p_num_hes VARCHAR(20), IN p_estado VARCHAR(20))
BEGIN
  DECLARE v_firma VARCHAR(20);
  IF p_estado NOT IN ('Aprobada', 'Rechazada', 'Retirada') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Estado no válido: use Aprobada, Rechazada o Retirada';
  END IF;
  SELECT i.Firma_contratista INTO v_firma
  FROM HES h JOIN INSPECCION_OBLIGACIONES i ON i.Num_inspeccion = h.Num_inspeccion
  WHERE h.Num_HES = p_num_hes;
  IF v_firma IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La HES no existe';
  END IF;
  IF p_estado = 'Aprobada' AND v_firma <> 'Firmado' THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'No se puede aprobar la HES: el formato no está firmado por la contratista';
  END IF;
  UPDATE HES SET Estado = p_estado WHERE Num_HES = p_num_hes;
END$$

-- Eliminación lógica de una HES: queda en estado Anulada
CREATE PROCEDURE sp_hes_anular(IN p_num_hes VARCHAR(20))
BEGIN
  IF NOT EXISTS (SELECT 1 FROM HES WHERE Num_HES = p_num_hes) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La HES no existe';
  END IF;
  UPDATE HES SET Estado = 'Anulada' WHERE Num_HES = p_num_hes;
END$$

-- ---------------------------------------------------------------- OBSERVACION

CREATE PROCEDURE sp_observacion_obtener(IN p_num_hes VARCHAR(20), IN p_num_observacion SMALLINT UNSIGNED)
BEGIN
  SELECT o.Num_HES, o.Num_observacion, o.Fecha_observacion, o.Comentario, h.Estado
  FROM OBSERVACION o JOIN HES h ON h.Num_HES = o.Num_HES
  WHERE o.Num_HES = p_num_hes AND o.Num_observacion = p_num_observacion;
END$$

-- Registra una observación con el siguiente número de la HES
CREATE PROCEDURE sp_observacion_registrar(IN p_num_hes VARCHAR(20), IN p_fecha DATE, IN p_comentario VARCHAR(600))
BEGIN
  DECLARE v_numero SMALLINT UNSIGNED;
  DECLARE v_emision DATE;
  IF NULLIF(TRIM(p_comentario), '') IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El comentario de la observación es obligatorio';
  END IF;
  SELECT Fecha_emision INTO v_emision FROM HES WHERE Num_HES = p_num_hes;
  IF v_emision IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La HES no existe';
  END IF;
  IF COALESCE(p_fecha, CURDATE()) < v_emision THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'La fecha de la observación no puede ser anterior a la emisión de la HES';
  END IF;
  SELECT COALESCE(MAX(Num_observacion), 0) + 1 INTO v_numero FROM OBSERVACION WHERE Num_HES = p_num_hes;
  INSERT INTO OBSERVACION (Num_HES, Num_observacion, Fecha_observacion, Comentario)
  VALUES (p_num_hes, v_numero, COALESCE(p_fecha, CURDATE()), TRIM(p_comentario));
  SELECT v_numero AS Num_observacion;
END$$

-- Corrige el comentario de una observación
CREATE PROCEDURE sp_observacion_actualizar(IN p_num_hes VARCHAR(20), IN p_num_observacion SMALLINT UNSIGNED,
                                           IN p_comentario VARCHAR(600))
BEGIN
  IF NULLIF(TRIM(p_comentario), '') IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El comentario de la observación es obligatorio';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM OBSERVACION WHERE Num_HES = p_num_hes AND Num_observacion = p_num_observacion) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La observación no existe';
  END IF;
  UPDATE OBSERVACION SET Comentario = TRIM(p_comentario)
  WHERE Num_HES = p_num_hes AND Num_observacion = p_num_observacion;
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
