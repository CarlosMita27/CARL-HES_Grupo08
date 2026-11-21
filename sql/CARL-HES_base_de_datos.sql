-- ============================================================================
-- CARL-HES - Control y Aprobación de la Revisión y Liberación de HES
-- Base de datos hes_spcc completa (script consolidado), versión 1.0
-- Gestión de Datos e Información - UCSM 2026 - Grupo 08
-- Gestor: MySQL 8.0 con el motor InnoDB
--
-- Reúne, en orden, los scripts 01, 02, 04, 05, 06, 07 y 08 de la carpeta sql:
-- creación de la base, datos de prueba, historial, eliminación lógica, usuario
-- del aplicativo, 63 procedimientos almacenados y 22 triggers.
--
-- Ejecutar como root (crea el usuario app_hes). Elimina y vuelve a crear las
-- bases hes_spcc y hes_spcc_historico, por lo que siempre parte de cero.
-- En MySQL Workbench: File > Open SQL Script y luego Execute (rayo).
-- ============================================================================


-- ############################################################################
-- PARTE 1 DE 7: 01_crear_base_datos_hes_spcc.sql
-- Creación de la base hes_spcc
-- ############################################################################

-- ============================================================================
-- Base de datos: revisión y liberación de la HES (SPCC)
-- Gestión de Datos e Información - UCSM. Cuarta Entrega: script de creación
-- Gestor: MySQL 8.0 con el motor InnoDB
-- Contenido: 19 tablas, claves primarias, claves foráneas, restricciones
--            UNIQUE y CHECK, triggers de fechas e índices del diseñador.
-- ============================================================================

DROP DATABASE IF EXISTS hes_spcc;
CREATE DATABASE hes_spcc DEFAULT CHARACTER SET utf8mb4;
USE hes_spcc;

-- ----------------------------------------------------------------------------
-- TABLAS MAESTRAS
-- ----------------------------------------------------------------------------

CREATE TABLE CONTRATISTA (
  RUC          CHAR(11)     NOT NULL,
  Razon_social VARCHAR(100) NOT NULL,
  CONSTRAINT pk_contratista PRIMARY KEY (RUC),
  CONSTRAINT ck_contratista_ruc
    CHECK (RUC REGEXP '^[0-9]{11}$')
) ENGINE = InnoDB;

CREATE TABLE CENTRO_COSTO (
  Cod_centro_costo    VARCHAR(10) NOT NULL,
  Nombre_centro_costo VARCHAR(80) NOT NULL,
  CONSTRAINT pk_centro_costo PRIMARY KEY (Cod_centro_costo),
  CONSTRAINT uq_centro_costo_nombre_centro_costo UNIQUE (Nombre_centro_costo),
  CONSTRAINT ck_centro_costo_cod
    CHECK (Cod_centro_costo REGEXP '^[A-Za-z0-9]+$')
) ENGINE = InnoDB;

CREATE TABLE CARGO (
  Cod_cargo    SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
  Nombre_cargo VARCHAR(80)       NOT NULL,
  CONSTRAINT pk_cargo PRIMARY KEY (Cod_cargo),
  CONSTRAINT uq_cargo_nombre_cargo UNIQUE (Nombre_cargo)
) ENGINE = InnoDB;

CREATE TABLE RECAUDADORA (
  Cod_entidad    SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
  Nombre_entidad VARCHAR(60)       NOT NULL,
  CONSTRAINT pk_recaudadora PRIMARY KEY (Cod_entidad),
  CONSTRAINT uq_recaudadora_nombre_entidad UNIQUE (Nombre_entidad)
) ENGINE = InnoDB;

CREATE TABLE OBLIGACION_TRIBUTARIA (
  Cod_obligacion VARCHAR(4)  NOT NULL,
  Nom_obligacion VARCHAR(40) NOT NULL,
  CONSTRAINT pk_obligacion_tributaria PRIMARY KEY (Cod_obligacion),
  CONSTRAINT uq_obligacion_tributaria_nom_obligacion UNIQUE (Nom_obligacion),
  CONSTRAINT ck_obligacion_tributaria_cod
    CHECK (Cod_obligacion REGEXP '^[0-9][.][0-9]{1,2}$')
) ENGINE = InnoDB;

CREATE TABLE OBLIGACION_LEGAL (
  Cod_obligacion_legal    CHAR(3)     NOT NULL,
  Nombre_obligacion_legal VARCHAR(80) NOT NULL,
  CONSTRAINT pk_obligacion_legal PRIMARY KEY (Cod_obligacion_legal),
  CONSTRAINT uq_obligacion_legal_nombre_obligacion_legal UNIQUE (Nombre_obligacion_legal),
  CONSTRAINT ck_obligacion_legal_cod
    CHECK (Cod_obligacion_legal REGEXP '^[0-9][.][0-9]$')
) ENGINE = InnoDB;

CREATE TABLE TELEFONO_CONTRATISTA (
  RUC      CHAR(11) NOT NULL,
  Telefono CHAR(9)  NOT NULL,
  CONSTRAINT pk_telefono_contratista PRIMARY KEY (RUC, Telefono),
  CONSTRAINT fk_telefono_contratista_ruc
    FOREIGN KEY (RUC) REFERENCES CONTRATISTA (RUC),
  CONSTRAINT ck_telefono_contratista_telefono
    CHECK (Telefono REGEXP '^[0-9]{9}$')
) ENGINE = InnoDB;

CREATE TABLE ANALISTA (
  Num_registro CHAR(6)           NOT NULL,
  Apellidos    VARCHAR(50)       NOT NULL,
  Nombres      VARCHAR(50)       NOT NULL,
  Cod_cargo    SMALLINT UNSIGNED NOT NULL,
  CONSTRAINT pk_analista PRIMARY KEY (Num_registro),
  CONSTRAINT fk_analista_cod_cargo
    FOREIGN KEY (Cod_cargo) REFERENCES CARGO (Cod_cargo),
  CONSTRAINT ck_analista_registro
    CHECK (Num_registro REGEXP '^[0-9]{6}$')
) ENGINE = InnoDB;

CREATE TABLE CONTRATO (
  Num_contrato          CHAR(9)       NOT NULL,
  Monto_total           DECIMAL(11,2) NOT NULL,
  RUC                   CHAR(11)      NOT NULL,
  Cod_centro_costo      VARCHAR(10)   NOT NULL,
  Num_registro_analista CHAR(6)       NOT NULL,
  CONSTRAINT pk_contrato PRIMARY KEY (Num_contrato),
  CONSTRAINT fk_contrato_ruc
    FOREIGN KEY (RUC) REFERENCES CONTRATISTA (RUC),
  CONSTRAINT fk_contrato_cod_centro_costo
    FOREIGN KEY (Cod_centro_costo) REFERENCES CENTRO_COSTO (Cod_centro_costo),
  CONSTRAINT fk_contrato_num_registro_analista
    FOREIGN KEY (Num_registro_analista) REFERENCES ANALISTA (Num_registro),
  CONSTRAINT ck_contrato_num
    CHECK (Num_contrato REGEXP '^CT-[0-9]{6}$'),
  CONSTRAINT ck_contrato_monto
    CHECK (Monto_total > 0)
) ENGINE = InnoDB;

CREATE TABLE TRABAJADOR (
  DNI       CHAR(8)     NOT NULL,
  Apellidos VARCHAR(50) NOT NULL,
  Nombres   VARCHAR(50) NOT NULL,
  RUC       CHAR(11)    NOT NULL,
  CONSTRAINT pk_trabajador PRIMARY KEY (DNI),
  CONSTRAINT fk_trabajador_ruc
    FOREIGN KEY (RUC) REFERENCES CONTRATISTA (RUC),
  CONSTRAINT ck_trabajador_dni
    CHECK (DNI REGEXP '^[0-9]{8}$')
) ENGINE = InnoDB;

-- ----------------------------------------------------------------------------
-- TABLAS TRANSACCIONALES
-- ----------------------------------------------------------------------------

CREATE TABLE INSPECCION_OBLIGACIONES (
  Num_inspeccion    CHAR(15) NOT NULL,
  Periodo           CHAR(6)  NOT NULL,
  Firma_contratista ENUM('Firmado', 'No firmado') NOT NULL,
  CONSTRAINT pk_inspeccion_obligaciones PRIMARY KEY (Num_inspeccion),
  CONSTRAINT ck_inspeccion_obligaciones_num
    CHECK (Num_inspeccion REGEXP '^INS-[0-9]{4}-(0[1-9]|1[0-2])-[0-9]{3}$'),
  CONSTRAINT ck_inspeccion_obligaciones_periodo
    CHECK (Periodo REGEXP '^[0-9]{4}(0[1-9]|1[0-2])$')
) ENGINE = InnoDB;

CREATE TABLE HES (
  Num_HES        CHAR(6)       NOT NULL,
  Fecha_emision  DATE          NOT NULL,
  Estado         ENUM('Pendiente', 'Aprobada', 'Rechazada', 'Anulada', 'Retirada') NOT NULL DEFAULT 'Pendiente',
  Monto_servicio DECIMAL(11,2) NOT NULL,
  Num_inspeccion CHAR(15)      NOT NULL,
  Num_contrato   CHAR(9)       NOT NULL,
  CONSTRAINT pk_hes PRIMARY KEY (Num_HES),
  CONSTRAINT uq_hes_num_inspeccion UNIQUE (Num_inspeccion),
  CONSTRAINT fk_hes_num_inspeccion
    FOREIGN KEY (Num_inspeccion) REFERENCES INSPECCION_OBLIGACIONES (Num_inspeccion),
  CONSTRAINT fk_hes_num_contrato
    FOREIGN KEY (Num_contrato) REFERENCES CONTRATO (Num_contrato),
  CONSTRAINT ck_hes_num
    CHECK (Num_HES REGEXP '^[0-9]{6}$'),
  CONSTRAINT ck_hes_monto
    CHECK (Monto_servicio > 0)
) ENGINE = InnoDB;

CREATE TABLE OBSERVACION (
  Num_HES           CHAR(6)           NOT NULL,
  Num_observacion   SMALLINT UNSIGNED NOT NULL,
  Fecha_observacion DATE              NOT NULL,
  Comentario        VARCHAR(500)      NOT NULL,
  CONSTRAINT pk_observacion PRIMARY KEY (Num_HES, Num_observacion),
  CONSTRAINT fk_observacion_num_hes
    FOREIGN KEY (Num_HES) REFERENCES HES (Num_HES),
  CONSTRAINT ck_observacion_num
    CHECK (Num_observacion > 0)
) ENGINE = InnoDB;

CREATE TABLE REPORTE_ENTIDAD (
  Num_reporte    CHAR(15)          NOT NULL,
  Cod_entidad    SMALLINT UNSIGNED NOT NULL,
  Num_inspeccion CHAR(15)          NOT NULL,
  CONSTRAINT pk_reporte_entidad PRIMARY KEY (Num_reporte),
  CONSTRAINT fk_reporte_entidad_cod_entidad
    FOREIGN KEY (Cod_entidad) REFERENCES RECAUDADORA (Cod_entidad),
  CONSTRAINT fk_reporte_entidad_num_inspeccion
    FOREIGN KEY (Num_inspeccion) REFERENCES INSPECCION_OBLIGACIONES (Num_inspeccion),
  CONSTRAINT ck_reporte_entidad_num
    CHECK (Num_reporte REGEXP '^REP-[0-9]{4}(0[1-9]|1[0-2])-[0-9]{4}$')
) ENGINE = InnoDB;

CREATE TABLE BOLETA_PAGO (
  Num_boleta       CHAR(15) NOT NULL,
  Firma_trabajador ENUM('Firmada', 'No firmada') NOT NULL,
  DNI              CHAR(8)  NOT NULL,
  Num_inspeccion   CHAR(15) NOT NULL,
  CONSTRAINT pk_boleta_pago PRIMARY KEY (Num_boleta),
  CONSTRAINT fk_boleta_pago_dni
    FOREIGN KEY (DNI) REFERENCES TRABAJADOR (DNI),
  CONSTRAINT fk_boleta_pago_num_inspeccion
    FOREIGN KEY (Num_inspeccion) REFERENCES INSPECCION_OBLIGACIONES (Num_inspeccion),
  CONSTRAINT ck_boleta_pago_num
    CHECK (Num_boleta REGEXP '^BOL-[0-9]{4}(0[1-9]|1[0-2])-[0-9]{4}$')
) ENGINE = InnoDB;

CREATE TABLE DECLARACION_JURADA (
  Num_declaracion       CHAR(13) NOT NULL,
  Fecha_compromiso_pago DATE     NOT NULL,
  Num_inspeccion        CHAR(15) NOT NULL,
  CONSTRAINT pk_declaracion_jurada PRIMARY KEY (Num_declaracion),
  CONSTRAINT fk_declaracion_jurada_num_inspeccion
    FOREIGN KEY (Num_inspeccion) REFERENCES INSPECCION_OBLIGACIONES (Num_inspeccion),
  CONSTRAINT ck_declaracion_jurada_num
    CHECK (Num_declaracion REGEXP '^DJ-[0-9]{4}(0[1-9]|1[0-2])-[0-9]{3}$')
) ENGINE = InnoDB;

CREATE TABLE DECLARA (
  Num_inspeccion  CHAR(15)      NOT NULL,
  Cod_obligacion  VARCHAR(4)    NOT NULL,
  Monto_declarado DECIMAL(11,2) NULL,
  Monto_pagado    DECIMAL(11,2) NULL,
  Mora            DECIMAL(11,2) NULL,
  Fecha_pago      DATE          NULL,
  CONSTRAINT pk_declara PRIMARY KEY (Num_inspeccion, Cod_obligacion),
  CONSTRAINT fk_declara_num_inspeccion
    FOREIGN KEY (Num_inspeccion) REFERENCES INSPECCION_OBLIGACIONES (Num_inspeccion),
  CONSTRAINT fk_declara_cod_obligacion
    FOREIGN KEY (Cod_obligacion) REFERENCES OBLIGACION_TRIBUTARIA (Cod_obligacion),
  CONSTRAINT ck_declara_declarado
    CHECK (Monto_declarado >= 0),
  CONSTRAINT ck_declara_pagado
    CHECK (Monto_pagado >= 0),
  CONSTRAINT ck_declara_mora
    CHECK (Mora > 0)
) ENGINE = InnoDB;

CREATE TABLE VERIFICA (
  Num_inspeccion       CHAR(15) NOT NULL,
  Cod_obligacion_legal CHAR(3)  NOT NULL,
  Cumplimiento         ENUM('OK', 'No aplica') NOT NULL,
  CONSTRAINT pk_verifica PRIMARY KEY (Num_inspeccion, Cod_obligacion_legal),
  CONSTRAINT fk_verifica_num_inspeccion
    FOREIGN KEY (Num_inspeccion) REFERENCES INSPECCION_OBLIGACIONES (Num_inspeccion),
  CONSTRAINT fk_verifica_cod_obligacion_legal
    FOREIGN KEY (Cod_obligacion_legal) REFERENCES OBLIGACION_LEGAL (Cod_obligacion_legal)
) ENGINE = InnoDB;

CREATE TABLE RESPALDA (
  Num_reporte      CHAR(15)      NOT NULL,
  Cod_obligacion   VARCHAR(4)    NOT NULL,
  Monto_adeudado   DECIMAL(11,2) NOT NULL,
  Monto_pagado_rep DECIMAL(11,2) NOT NULL,
  CONSTRAINT pk_respalda PRIMARY KEY (Num_reporte, Cod_obligacion),
  CONSTRAINT fk_respalda_num_reporte
    FOREIGN KEY (Num_reporte) REFERENCES REPORTE_ENTIDAD (Num_reporte),
  CONSTRAINT fk_respalda_cod_obligacion
    FOREIGN KEY (Cod_obligacion) REFERENCES OBLIGACION_TRIBUTARIA (Cod_obligacion),
  CONSTRAINT ck_respalda_adeudado
    CHECK (Monto_adeudado >= 0),
  CONSTRAINT ck_respalda_pagado
    CHECK (Monto_pagado_rep >= 0)
) ENGINE = InnoDB;

-- ----------------------------------------------------------------------------
-- TRIGGERS: fechas que no pueden ser posteriores a la fecha actual
-- ----------------------------------------------------------------------------
DELIMITER $$

CREATE TRIGGER tr_hes_fecha_bi BEFORE INSERT ON HES
FOR EACH ROW
BEGIN
  IF NEW.Fecha_emision > CURDATE() THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La fecha de emisión de la HES no puede ser posterior a la fecha actual';
  END IF;
END$$

CREATE TRIGGER tr_hes_fecha_bu BEFORE UPDATE ON HES
FOR EACH ROW
BEGIN
  IF NEW.Fecha_emision > CURDATE() THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La fecha de emisión de la HES no puede ser posterior a la fecha actual';
  END IF;
END$$

CREATE TRIGGER tr_observacion_fecha_bi BEFORE INSERT ON OBSERVACION
FOR EACH ROW
BEGIN
  IF NEW.Fecha_observacion > CURDATE() THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La fecha de la observación no puede ser posterior a la fecha actual';
  END IF;
END$$

CREATE TRIGGER tr_observacion_fecha_bu BEFORE UPDATE ON OBSERVACION
FOR EACH ROW
BEGIN
  IF NEW.Fecha_observacion > CURDATE() THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La fecha de la observación no puede ser posterior a la fecha actual';
  END IF;
END$$

CREATE TRIGGER tr_declara_fecha_bi BEFORE INSERT ON DECLARA
FOR EACH ROW
BEGIN
  IF NEW.Fecha_pago IS NOT NULL AND NEW.Fecha_pago > CURDATE() THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La fecha de pago no puede ser posterior a la fecha actual';
  END IF;
END$$

CREATE TRIGGER tr_declara_fecha_bu BEFORE UPDATE ON DECLARA
FOR EACH ROW
BEGIN
  IF NEW.Fecha_pago IS NOT NULL AND NEW.Fecha_pago > CURDATE() THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La fecha de pago no puede ser posterior a la fecha actual';
  END IF;
END$$

DELIMITER ;

-- ----------------------------------------------------------------------------
-- ÍNDICES DEFINIDOS POR EL DISEÑADOR
-- (los de claves primarias, únicas y foráneas se crean junto con las tablas)
-- ----------------------------------------------------------------------------
CREATE INDEX idx_hes_estado_fecha      ON HES (Estado, Fecha_emision);
CREATE INDEX idx_inspeccion_periodo    ON INSPECCION_OBLIGACIONES (Periodo);
CREATE INDEX idx_trabajador_apellidos  ON TRABAJADOR (Apellidos, Nombres);
CREATE INDEX idx_contratista_razon     ON CONTRATISTA (Razon_social);

-- ----------------------------------------------------------------------------
-- VERIFICACIÓN
-- ----------------------------------------------------------------------------
SHOW TABLES;

SELECT COUNT(*) AS Claves_foraneas
FROM information_schema.REFERENTIAL_CONSTRAINTS
WHERE CONSTRAINT_SCHEMA = 'hes_spcc';


-- ############################################################################
-- PARTE 2 DE 7: 02_insertar_datos_hes_spcc.sql
-- Datos de enero a septiembre de 2026
-- ############################################################################

-- ============================================================================
-- Base de datos: revisión y liberación de la HES (SPCC)
-- Cuarta Entrega: inserción de datos de prueba
-- Datos ficticios aproximados a los reales: contratistas, trabajadores, montos y
-- códigos no corresponden a información real de SPCC (Anexo A del informe).
-- Periodo cubierto: enero a septiembre de 2026. Ejecutar después del script de creación.
-- ============================================================================

USE hes_spcc;

-- ----------------------------------------------------------------------------
-- TABLAS MAESTRAS
-- ----------------------------------------------------------------------------

-- CONTRATISTA (12 filas)
INSERT INTO CONTRATISTA (RUC, Razon_social) VALUES
  ('20487213561', 'Montajes Electromecánicos del Sur S.A.C.'),
  ('20516340275', 'Servicios Generales Ilo E.I.R.L.'),
  ('20492876055', 'Transportes Mineros Candarave S.A.C.'),
  ('20520791842', 'Ingeniería y Mantenimiento Industrial Andino S.A.C.'),
  ('20476159327', 'Seguridad Integral Tacna S.R.L.'),
  ('20503487617', 'Constructora Altiplano Moquegua S.A.C.'),
  ('20469072135', 'Limpieza Industrial Pacífico Sur S.A.C.'),
  ('20531826401', 'Soluciones Geotécnicas Arequipa S.A.C.'),
  ('20480563973', 'Alimentación y Hotelería Minera S.A.C.'),
  ('20519204631', 'Mantenimiento de Equipos Pesados Toquepala S.A.C.'),
  ('20497315086', 'Topografía y Mediciones del Sur E.I.R.L.'),
  ('20524670195', 'Tecnología y Redes Industriales S.A.C.');

-- CENTRO_COSTO (10 filas)
INSERT INTO CENTRO_COSTO (Cod_centro_costo, Nombre_centro_costo) VALUES
  ('TQMIN01', 'Mina Toquepala - Operaciones Mina'),
  ('TQCON02', 'Concentradora Toquepala'),
  ('TQMAN03', 'Mantenimiento de Planta Toquepala'),
  ('CJMIN01', 'Mina Cuajone - Operaciones Mina'),
  ('CJCON02', 'Concentradora Cuajone'),
  ('ILFUN01', 'Fundición Ilo'),
  ('ILREF02', 'Refinería Ilo'),
  ('ILPUE03', 'Puerto Ilo'),
  ('SGSSO01', 'Seguridad y Salud Ocupacional'),
  ('SGTIC02', 'Tecnologías de la Información');

-- CARGO (3 filas)
INSERT INTO CARGO (Cod_cargo, Nombre_cargo) VALUES
  (1, 'Licitaciones y Cotizaciones'),
  (2, 'Analista de Contratos'),
  (3, 'Analista Senior de Contratos');

-- RECAUDADORA (12 filas)
INSERT INTO RECAUDADORA (Cod_entidad, Nombre_entidad) VALUES
  (1, 'SUNAT'),
  (2, 'EsSalud'),
  (3, 'ONP'),
  (4, 'AFP Integra'),
  (5, 'AFP Prima'),
  (6, 'AFP Profuturo'),
  (7, 'AFP Habitat'),
  (8, 'Rímac Seguros'),
  (9, 'Pacífico Seguros'),
  (10, 'La Positiva Seguros'),
  (11, 'SENCICO'),
  (12, 'SENATI');

-- OBLIGACION_TRIBUTARIA (13 filas)
INSERT INTO OBLIGACION_TRIBUTARIA (Cod_obligacion, Nom_obligacion) VALUES
  ('1.1', 'IGV'),
  ('1.2', 'Renta'),
  ('1.3', 'EsSalud'),
  ('1.4', 'SCTR salud'),
  ('1.5', 'SCTR invalidez y sobrevivencia'),
  ('1.6', 'ONP'),
  ('1.7', 'AFP'),
  ('1.8', 'CTS'),
  ('1.9', 'Gratificaciones'),
  ('1.10', 'Sencico'),
  ('1.11', 'Senati'),
  ('1.12', 'Vida Ley'),
  ('1.13', 'Póliza de seguro de vida');

-- OBLIGACION_LEGAL (4 filas)
INSERT INTO OBLIGACION_LEGAL (Cod_obligacion_legal, Nombre_obligacion_legal) VALUES
  ('2.1', 'Planillas que registran a todo el personal en actividad'),
  ('2.2', 'Boletas de pago firmadas'),
  ('2.5', 'Vacaciones y descansos remunerados'),
  ('2.6', 'Asignación familiar');

-- TELEFONO_CONTRATISTA (21 filas)
INSERT INTO TELEFONO_CONTRATISTA (RUC, Telefono) VALUES
  ('20487213561', '959318274'),
  ('20487213561', '054283615'),
  ('20516340275', '953772140'),
  ('20492876055', '952604318'),
  ('20492876055', '052415873'),
  ('20492876055', '987154026'),
  ('20520791842', '974526391'),
  ('20520791842', '054271946'),
  ('20476159327', '952318407'),
  ('20476159327', '052426690'),
  ('20503487617', '953148820'),
  ('20469072135', '953506127'),
  ('20469072135', '053483312'),
  ('20531826401', '958712063'),
  ('20480563973', '959047812'),
  ('20480563973', '054239174'),
  ('20519204631', '952871304'),
  ('20519204631', '052438027'),
  ('20497315086', '958330715'),
  ('20524670195', '974105638'),
  ('20524670195', '054256480');

-- ANALISTA (8 filas)
INSERT INTO ANALISTA (Num_registro, Apellidos, Nombres, Cod_cargo) VALUES
  ('103871', 'Quispe Huamán', 'Rosa Elena', 2),
  ('104026', 'Paredes Linares', 'Carla Patricia', 2),
  ('104233', 'Valdivia Torres', 'Jorge Luis', 3),
  ('104390', 'Chávez Mamani', 'Lucía Fernanda', 1),
  ('104458', 'Zegarra Rivera', 'Diego Alonso', 2),
  ('104611', 'Apaza Condori', 'Milagros Ruth', 1),
  ('104702', 'Delgado Salas', 'Renato César', 2),
  ('104815', 'Flores Ccama', 'Andrea Sofía', 2);

-- CONTRATO (16 filas)
INSERT INTO CONTRATO (Num_contrato, Monto_total, RUC, Cod_centro_costo, Num_registro_analista) VALUES
  ('CT-004517', 2850000.00, '20487213561', 'TQMAN03', '104390'),
  ('CT-004532', 1920000.00, '20480563973', 'TQMIN01', '104390'),
  ('CT-004608', 1260000.00, '20476159327', 'ILFUN01', '104390'),
  ('CT-004671', 780000.00, '20469072135', 'ILREF02', '104390'),
  ('CT-004402', 960000.00, '20516340275', 'ILPUE03', '103871'),
  ('CT-004455', 3480000.00, '20492876055', 'CJMIN01', '103871'),
  ('CT-004589', 2160000.00, '20520791842', 'CJCON02', '104026'),
  ('CT-004613', 3150000.00, '20503487617', 'TQCON02', '104026'),
  ('CT-004640', 1140000.00, '20531826401', 'TQMIN01', '104233'),
  ('CT-004655', 2640000.00, '20519204631', 'TQMAN03', '104233'),
  ('CT-004688', 540000.00, '20497315086', 'CJMIN01', '104458'),
  ('CT-004702', 690000.00, '20524670195', 'SGTIC02', '104458'),
  ('CT-004719', 1740000.00, '20487213561', 'ILFUN01', '104611'),
  ('CT-004733', 1080000.00, '20476159327', 'CJMIN01', '104611'),
  ('CT-004750', 1680000.00, '20480563973', 'CJMIN01', '104702'),
  ('CT-004768', 1320000.00, '20520791842', 'ILREF02', '104702');

-- TRABAJADOR (104 filas)
INSERT INTO TRABAJADOR (DNI, Apellidos, Nombres, RUC) VALUES
  ('48299424', 'Salas Choque', 'Wilber', '20487213561'),
  ('75955639', 'Ticona Ccallo', 'Noemí', '20487213561'),
  ('70180423', 'Mamani Huamán', 'Juan Pablo', '20487213561'),
  ('70907576', 'Ticona Huamán', 'Percy', '20487213561'),
  ('72315353', 'Valdivia Flores', 'Percy', '20487213561'),
  ('71342606', 'Choque Apaza', 'Cristian', '20487213561'),
  ('72015528', 'Salas Apaza', 'Wilber', '20487213561'),
  ('40065537', 'Mamani Zegarra', 'Yesenia', '20487213561'),
  ('73206828', 'Medina Salas', 'Cristian', '20480563973'),
  ('48126126', 'Rivera Zegarra', 'Elizabeth', '20480563973'),
  ('73596879', 'Apaza Choque', 'Óscar', '20480563973'),
  ('47979758', 'Mamani Ticona', 'Walter', '20480563973'),
  ('47336743', 'Pari Choque', 'Marco Antonio', '20480563973'),
  ('40865140', 'Rivera Condori', 'Karina', '20480563973'),
  ('43364705', 'Cutipa Gutiérrez', 'Raúl', '20480563973'),
  ('76581112', 'Coaquira Cutipa', 'Noemí', '20476159327'),
  ('47165365', 'Apaza Delgado', 'Raúl', '20476159327'),
  ('40131777', 'Valdivia Coaquira', 'Luis Alberto', '20476159327'),
  ('71873068', 'Apaza Choque', 'Fredy', '20476159327'),
  ('70079389', 'Ramos Choque', 'Miguel Ángel', '20476159327'),
  ('45457987', 'Cáceres Paredes', 'Milagros', '20476159327'),
  ('45731722', 'Gutiérrez Ccallo', 'Cristian', '20476159327'),
  ('42436230', 'Zegarra Choque', 'Elvis', '20469072135'),
  ('46083695', 'Medina Coaquira', 'Percy', '20469072135'),
  ('72275217', 'Mamani Choque', 'Walter', '20469072135'),
  ('43510587', 'Valdivia Flores', 'José Carlos', '20469072135'),
  ('71271679', 'Torres Medina', 'Rosa', '20469072135'),
  ('74338638', 'Valdivia Mamani', 'Raúl', '20469072135'),
  ('42173460', 'Apaza Cutipa', 'Wilber', '20516340275'),
  ('71523270', 'Llerena Vargas', 'Óscar', '20516340275'),
  ('75296053', 'Torres Valdivia', 'Walter', '20516340275'),
  ('46830184', 'Ramos Llerena', 'Alexis', '20516340275'),
  ('43368451', 'Quispe Gutiérrez', 'Gladys', '20516340275'),
  ('40916276', 'Valdivia Rivera', 'Elizabeth', '20492876055'),
  ('73963527', 'Salas Ticona', 'Jhon', '20492876055'),
  ('43892914', 'Coaquira Torres', 'Miguel Ángel', '20492876055'),
  ('75444200', 'Chávez Torres', 'Noemí', '20492876055'),
  ('40644902', 'Zegarra Condori', 'Wilber', '20492876055'),
  ('45520843', 'Pari Paredes', 'Cristian', '20492876055'),
  ('76965074', 'Delgado Cutipa', 'Percy', '20492876055'),
  ('41579947', 'Choque Llerena', 'Marco Antonio', '20492876055'),
  ('73257171', 'Cáceres Quispe', 'Hernán', '20520791842'),
  ('46500139', 'Mamani Choque', 'Wilber', '20520791842'),
  ('73930805', 'Huamán Valdivia', 'Cristian', '20520791842'),
  ('42812093', 'Rivera Llerena', 'Yesenia', '20520791842'),
  ('73112728', 'Paredes Zegarra', 'Óscar', '20520791842'),
  ('75751651', 'Cutipa Pari', 'Fredy', '20520791842'),
  ('47388246', 'Chávez Apaza', 'Wilber', '20520791842'),
  ('42163254', 'Quispe Salas', 'Milagros', '20503487617'),
  ('40177862', 'Medina Cáceres', 'Karina', '20503487617'),
  ('43708948', 'Quispe Flores', 'Rubén', '20503487617'),
  ('46625414', 'Coaquira Quispe', 'Gladys', '20503487617'),
  ('74813733', 'Valdivia Condori', 'Karina', '20503487617'),
  ('45414231', 'Zegarra Ccallo', 'Rubén', '20503487617'),
  ('42240425', 'Medina Condori', 'Rubén', '20503487617'),
  ('71518007', 'Ticona Chávez', 'Marco Antonio', '20503487617'),
  ('71815739', 'Flores Mamani', 'Jhon', '20531826401'),
  ('43324473', 'Coaquira Choque', 'Alexis', '20531826401'),
  ('73928916', 'Salas Llerena', 'Gladys', '20531826401'),
  ('46352975', 'Salas Apaza', 'Edwin', '20531826401'),
  ('46230283', 'Condori Paredes', 'Noemí', '20531826401'),
  ('44441759', 'Quispe Rivera', 'Hernán', '20519204631'),
  ('74915035', 'Gutiérrez Ticona', 'Rosa', '20519204631'),
  ('46476573', 'Coaquira Condori', 'Rosa', '20519204631'),
  ('71728206', 'Quispe Chávez', 'Juan Pablo', '20519204631'),
  ('71675500', 'Cutipa Torres', 'Fredy', '20519204631'),
  ('71012734', 'Rojas Ccallo', 'Edwin', '20519204631'),
  ('42982232', 'Ccallo Mamani', 'Juan Pablo', '20519204631'),
  ('72879685', 'Benavente Gutiérrez', 'Milagros', '20519204631'),
  ('40752228', 'Rojas Ticona', 'Rosa', '20497315086'),
  ('74002617', 'Choque Rojas', 'Yesenia', '20497315086'),
  ('40908215', 'Salas Medina', 'Rosa', '20497315086'),
  ('75587395', 'Zegarra Rojas', 'Edwin', '20497315086'),
  ('71905242', 'Mamani Coaquira', 'Yesenia', '20497315086'),
  ('41406079', 'Medina Benavente', 'Wilber', '20524670195'),
  ('72387158', 'Valdivia Ccallo', 'Luis Alberto', '20524670195'),
  ('46695880', 'Quispe Choque', 'Karina', '20524670195'),
  ('74743120', 'Condori Delgado', 'Rosa', '20524670195'),
  ('71383122', 'Condori Ramos', 'Walter', '20524670195'),
  ('76652718', 'Torres Ramos', 'Noemí', '20487213561'),
  ('76006912', 'Valdivia Quispe', 'Ana María', '20487213561'),
  ('71540558', 'Cáceres Gutiérrez', 'Edwin', '20487213561'),
  ('43751737', 'Llerena Ramos', 'Walter', '20487213561'),
  ('44376048', 'Benavente Ticona', 'Noemí', '20487213561'),
  ('43761680', 'Cutipa Cáceres', 'Milagros', '20487213561'),
  ('76065004', 'Coaquira Paredes', 'Jhon', '20476159327'),
  ('47728258', 'Ramos Ccallo', 'Elizabeth', '20476159327'),
  ('76953642', 'Choque Rivera', 'Noemí', '20476159327'),
  ('42276165', 'Medina Ramos', 'Ana María', '20476159327'),
  ('76616396', 'Torres Rojas', 'Walter', '20476159327'),
  ('72116961', 'Ramos Quispe', 'Fredy', '20476159327'),
  ('45950756', 'Gutiérrez Cutipa', 'Jhon', '20480563973'),
  ('42219803', 'Rivera Zegarra', 'Wilber', '20480563973'),
  ('72502438', 'Coaquira Chávez', 'Jhon', '20480563973'),
  ('44423950', 'Zegarra Salas', 'Elvis', '20480563973'),
  ('45768741', 'Apaza Cáceres', 'Elvis', '20480563973'),
  ('72493759', 'Zegarra Apaza', 'Karina', '20480563973'),
  ('74368538', 'Condori Valdivia', 'Percy', '20480563973'),
  ('73899177', 'Flores Rojas', 'Elvis', '20520791842'),
  ('46724988', 'Rojas Quispe', 'Juan Pablo', '20520791842');
INSERT INTO TRABAJADOR (DNI, Apellidos, Nombres, RUC) VALUES
  ('45023399', 'Condori Ccallo', 'Percy', '20520791842'),
  ('74553619', 'Cutipa Choque', 'Hernán', '20520791842'),
  ('73363762', 'Ramos Paredes', 'Juan Pablo', '20520791842'),
  ('71080618', 'Llerena Coaquira', 'Percy', '20520791842');

-- ----------------------------------------------------------------------------
-- TABLAS TRANSACCIONALES
-- ----------------------------------------------------------------------------

-- INSPECCION_OBLIGACIONES (136 filas)
INSERT INTO INSPECCION_OBLIGACIONES (Num_inspeccion, Periodo, Firma_contratista) VALUES
  ('INS-2026-01-001', '202601', 'Firmado'),
  ('INS-2026-01-002', '202601', 'Firmado'),
  ('INS-2026-01-003', '202601', 'Firmado'),
  ('INS-2026-01-004', '202601', 'Firmado'),
  ('INS-2026-01-005', '202601', 'Firmado'),
  ('INS-2026-01-006', '202601', 'Firmado'),
  ('INS-2026-01-007', '202601', 'Firmado'),
  ('INS-2026-01-008', '202601', 'Firmado'),
  ('INS-2026-01-009', '202601', 'Firmado'),
  ('INS-2026-01-010', '202601', 'Firmado'),
  ('INS-2026-01-011', '202601', 'Firmado'),
  ('INS-2026-02-001', '202602', 'Firmado'),
  ('INS-2026-02-002', '202602', 'Firmado'),
  ('INS-2026-02-003', '202602', 'Firmado'),
  ('INS-2026-02-004', '202602', 'Firmado'),
  ('INS-2026-02-005', '202602', 'Firmado'),
  ('INS-2026-02-006', '202602', 'Firmado'),
  ('INS-2026-02-007', '202602', 'Firmado'),
  ('INS-2026-02-008', '202602', 'Firmado'),
  ('INS-2026-02-009', '202602', 'Firmado'),
  ('INS-2026-02-010', '202602', 'Firmado'),
  ('INS-2026-02-011', '202602', 'Firmado'),
  ('INS-2026-02-012', '202602', 'Firmado'),
  ('INS-2026-02-013', '202602', 'Firmado'),
  ('INS-2026-02-014', '202602', 'Firmado'),
  ('INS-2026-03-001', '202603', 'Firmado'),
  ('INS-2026-03-002', '202603', 'Firmado'),
  ('INS-2026-03-003', '202603', 'Firmado'),
  ('INS-2026-03-004', '202603', 'Firmado'),
  ('INS-2026-03-005', '202603', 'Firmado'),
  ('INS-2026-03-006', '202603', 'Firmado'),
  ('INS-2026-03-007', '202603', 'Firmado'),
  ('INS-2026-03-008', '202603', 'Firmado'),
  ('INS-2026-03-009', '202603', 'Firmado'),
  ('INS-2026-03-010', '202603', 'Firmado'),
  ('INS-2026-03-011', '202603', 'Firmado'),
  ('INS-2026-03-012', '202603', 'Firmado'),
  ('INS-2026-03-013', '202603', 'Firmado'),
  ('INS-2026-03-014', '202603', 'Firmado'),
  ('INS-2026-03-015', '202603', 'Firmado'),
  ('INS-2026-04-001', '202604', 'Firmado'),
  ('INS-2026-04-002', '202604', 'Firmado'),
  ('INS-2026-04-003', '202604', 'Firmado'),
  ('INS-2026-04-004', '202604', 'Firmado'),
  ('INS-2026-04-005', '202604', 'Firmado'),
  ('INS-2026-04-006', '202604', 'Firmado'),
  ('INS-2026-04-007', '202604', 'Firmado'),
  ('INS-2026-04-008', '202604', 'Firmado'),
  ('INS-2026-04-009', '202604', 'Firmado'),
  ('INS-2026-04-010', '202604', 'Firmado'),
  ('INS-2026-04-011', '202604', 'Firmado'),
  ('INS-2026-04-012', '202604', 'Firmado'),
  ('INS-2026-04-013', '202604', 'Firmado'),
  ('INS-2026-04-014', '202604', 'Firmado'),
  ('INS-2026-04-015', '202604', 'Firmado'),
  ('INS-2026-05-001', '202605', 'Firmado'),
  ('INS-2026-05-002', '202605', 'Firmado'),
  ('INS-2026-05-003', '202605', 'Firmado'),
  ('INS-2026-05-004', '202605', 'Firmado'),
  ('INS-2026-05-005', '202605', 'Firmado'),
  ('INS-2026-05-006', '202605', 'Firmado'),
  ('INS-2026-05-007', '202605', 'Firmado'),
  ('INS-2026-05-008', '202605', 'Firmado'),
  ('INS-2026-05-009', '202605', 'Firmado'),
  ('INS-2026-05-010', '202605', 'Firmado'),
  ('INS-2026-05-011', '202605', 'Firmado'),
  ('INS-2026-05-012', '202605', 'Firmado'),
  ('INS-2026-05-013', '202605', 'Firmado'),
  ('INS-2026-05-014', '202605', 'Firmado'),
  ('INS-2026-05-015', '202605', 'Firmado'),
  ('INS-2026-05-016', '202605', 'Firmado'),
  ('INS-2026-05-017', '202605', 'Firmado'),
  ('INS-2026-06-001', '202606', 'Firmado'),
  ('INS-2026-06-002', '202606', 'Firmado'),
  ('INS-2026-06-003', '202606', 'Firmado'),
  ('INS-2026-06-004', '202606', 'Firmado'),
  ('INS-2026-06-005', '202606', 'Firmado'),
  ('INS-2026-06-006', '202606', 'Firmado'),
  ('INS-2026-06-007', '202606', 'Firmado'),
  ('INS-2026-06-008', '202606', 'Firmado'),
  ('INS-2026-06-009', '202606', 'Firmado'),
  ('INS-2026-06-010', '202606', 'Firmado'),
  ('INS-2026-06-011', '202606', 'Firmado'),
  ('INS-2026-06-012', '202606', 'Firmado'),
  ('INS-2026-06-013', '202606', 'Firmado'),
  ('INS-2026-06-014', '202606', 'Firmado'),
  ('INS-2026-06-015', '202606', 'Firmado'),
  ('INS-2026-06-016', '202606', 'Firmado'),
  ('INS-2026-07-001', '202607', 'Firmado'),
  ('INS-2026-07-002', '202607', 'Firmado'),
  ('INS-2026-07-003', '202607', 'Firmado'),
  ('INS-2026-07-004', '202607', 'Firmado'),
  ('INS-2026-07-005', '202607', 'Firmado'),
  ('INS-2026-07-006', '202607', 'Firmado'),
  ('INS-2026-07-007', '202607', 'Firmado'),
  ('INS-2026-07-008', '202607', 'Firmado'),
  ('INS-2026-07-009', '202607', 'Firmado'),
  ('INS-2026-07-010', '202607', 'Firmado'),
  ('INS-2026-07-011', '202607', 'Firmado'),
  ('INS-2026-07-012', '202607', 'Firmado');
INSERT INTO INSPECCION_OBLIGACIONES (Num_inspeccion, Periodo, Firma_contratista) VALUES
  ('INS-2026-07-013', '202607', 'Firmado'),
  ('INS-2026-07-014', '202607', 'Firmado'),
  ('INS-2026-07-015', '202607', 'No firmado'),
  ('INS-2026-07-016', '202607', 'Firmado'),
  ('INS-2026-08-001', '202608', 'Firmado'),
  ('INS-2026-08-002', '202608', 'Firmado'),
  ('INS-2026-08-003', '202608', 'Firmado'),
  ('INS-2026-08-004', '202608', 'Firmado'),
  ('INS-2026-08-005', '202608', 'Firmado'),
  ('INS-2026-08-006', '202608', 'Firmado'),
  ('INS-2026-08-007', '202608', 'Firmado'),
  ('INS-2026-08-008', '202608', 'Firmado'),
  ('INS-2026-08-009', '202608', 'Firmado'),
  ('INS-2026-08-010', '202608', 'Firmado'),
  ('INS-2026-08-011', '202608', 'Firmado'),
  ('INS-2026-08-012', '202608', 'Firmado'),
  ('INS-2026-08-013', '202608', 'Firmado'),
  ('INS-2026-08-014', '202608', 'Firmado'),
  ('INS-2026-08-015', '202608', 'Firmado'),
  ('INS-2026-08-016', '202608', 'Firmado'),
  ('INS-2026-09-001', '202609', 'Firmado'),
  ('INS-2026-09-002', '202609', 'Firmado'),
  ('INS-2026-09-003', '202609', 'Firmado'),
  ('INS-2026-09-004', '202609', 'Firmado'),
  ('INS-2026-09-005', '202609', 'Firmado'),
  ('INS-2026-09-006', '202609', 'Firmado'),
  ('INS-2026-09-007', '202609', 'Firmado'),
  ('INS-2026-09-008', '202609', 'Firmado'),
  ('INS-2026-09-009', '202609', 'Firmado'),
  ('INS-2026-09-010', '202609', 'Firmado'),
  ('INS-2026-09-011', '202609', 'Firmado'),
  ('INS-2026-09-012', '202609', 'Firmado'),
  ('INS-2026-09-013', '202609', 'Firmado'),
  ('INS-2026-09-014', '202609', 'Firmado'),
  ('INS-2026-09-015', '202609', 'Firmado'),
  ('INS-2026-09-016', '202609', 'Firmado');

-- HES (136 filas)
INSERT INTO HES (Num_HES, Fecha_emision, Estado, Monto_servicio, Num_inspeccion, Num_contrato) VALUES
  ('005120', '2026-02-05', 'Aprobada', 42173.45, 'INS-2026-01-001', 'CT-004402'),
  ('005121', '2026-02-05', 'Aprobada', 123422.36, 'INS-2026-01-002', 'CT-004517'),
  ('005122', '2026-02-05', 'Aprobada', 102391.54, 'INS-2026-01-003', 'CT-004655'),
  ('005123', '2026-02-06', 'Aprobada', 145249.43, 'INS-2026-01-004', 'CT-004455'),
  ('005124', '2026-02-06', 'Aprobada', 28317.55, 'INS-2026-01-005', 'CT-004702'),
  ('005125', '2026-02-07', 'Aprobada', 75444.47, 'INS-2026-01-006', 'CT-004532'),
  ('005126', '2026-02-07', 'Aprobada', 49900.15, 'INS-2026-01-007', 'CT-004608'),
  ('005127', '2026-02-07', 'Aprobada', 65778.95, 'INS-2026-01-008', 'CT-004750'),
  ('005128', '2026-02-09', 'Aprobada', 46366.30, 'INS-2026-01-009', 'CT-004640'),
  ('005129', '2026-02-09', 'Aprobada', 46963.56, 'INS-2026-01-010', 'CT-004733'),
  ('005130', '2026-02-10', 'Aprobada', 83361.38, 'INS-2026-01-011', 'CT-004589'),
  ('005131', '2026-03-02', 'Aprobada', 49224.37, 'INS-2026-02-001', 'CT-004640'),
  ('005132', '2026-03-02', 'Aprobada', 70166.12, 'INS-2026-02-002', 'CT-004719'),
  ('005133', '2026-03-03', 'Aprobada', 38488.88, 'INS-2026-02-003', 'CT-004402'),
  ('005134', '2026-03-03', 'Aprobada', 73508.11, 'INS-2026-02-004', 'CT-004750'),
  ('005135', '2026-03-04', 'Aprobada', 125568.71, 'INS-2026-02-005', 'CT-004517'),
  ('005136', '2026-03-04', 'Retirada', 127006.07, 'INS-2026-02-006', 'CT-004613'),
  ('005137', '2026-03-05', 'Aprobada', 93070.52, 'INS-2026-02-007', 'CT-004589'),
  ('005138', '2026-03-07', 'Aprobada', 26597.38, 'INS-2026-02-008', 'CT-004702'),
  ('005139', '2026-03-09', 'Aprobada', 150672.39, 'INS-2026-02-009', 'CT-004455'),
  ('005140', '2026-03-09', 'Aprobada', 51220.20, 'INS-2026-02-010', 'CT-004608'),
  ('005141', '2026-03-09', 'Aprobada', 113038.34, 'INS-2026-02-011', 'CT-004655'),
  ('005142', '2026-03-09', 'Aprobada', 44697.00, 'INS-2026-02-012', 'CT-004733'),
  ('005143', '2026-03-10', 'Aprobada', 78034.97, 'INS-2026-02-013', 'CT-004532'),
  ('005144', '2026-03-11', 'Aprobada', 133887.89, 'INS-2026-02-014', 'CT-004613'),
  ('005145', '2026-04-02', 'Aprobada', 51151.37, 'INS-2026-03-001', 'CT-004608'),
  ('005146', '2026-04-02', 'Aprobada', 104682.05, 'INS-2026-03-002', 'CT-004655'),
  ('005147', '2026-04-02', 'Aprobada', 34011.11, 'INS-2026-03-003', 'CT-004671'),
  ('005148', '2026-04-02', 'Aprobada', 28809.21, 'INS-2026-03-004', 'CT-004702'),
  ('005149', '2026-04-03', 'Aprobada', 114835.04, 'INS-2026-03-005', 'CT-004517'),
  ('005150', '2026-04-04', 'Rechazada', 152241.62, 'INS-2026-03-006', 'CT-004455'),
  ('005151', '2026-04-04', 'Aprobada', 72180.92, 'INS-2026-03-007', 'CT-004750'),
  ('005152', '2026-04-05', 'Aprobada', 85743.10, 'INS-2026-03-008', 'CT-004589'),
  ('005153', '2026-04-06', 'Aprobada', 138655.27, 'INS-2026-03-009', 'CT-004613'),
  ('005154', '2026-04-06', 'Aprobada', 41493.04, 'INS-2026-03-010', 'CT-004733'),
  ('005155', '2026-04-07', 'Aprobada', 39265.73, 'INS-2026-03-011', 'CT-004402'),
  ('005156', '2026-04-08', 'Aprobada', 46606.37, 'INS-2026-03-012', 'CT-004640'),
  ('005157', '2026-04-08', 'Aprobada', 74754.83, 'INS-2026-03-013', 'CT-004719'),
  ('005158', '2026-04-10', 'Aprobada', 74630.92, 'INS-2026-03-014', 'CT-004532'),
  ('005159', '2026-04-12', 'Aprobada', 144356.17, 'INS-2026-03-015', 'CT-004455'),
  ('005160', '2026-05-02', 'Aprobada', 32577.36, 'INS-2026-04-001', 'CT-004671'),
  ('005161', '2026-05-03', 'Aprobada', 126725.05, 'INS-2026-04-002', 'CT-004613'),
  ('005162', '2026-05-03', 'Aprobada', 45729.35, 'INS-2026-04-003', 'CT-004733'),
  ('005163', '2026-05-04', 'Aprobada', 44637.35, 'INS-2026-04-004', 'CT-004640'),
  ('005164', '2026-05-05', 'Aprobada', 21196.40, 'INS-2026-04-005', 'CT-004688'),
  ('005165', '2026-05-06', 'Aprobada', 30115.75, 'INS-2026-04-006', 'CT-004702'),
  ('005166', '2026-05-07', 'Aprobada', 68066.00, 'INS-2026-04-007', 'CT-004750'),
  ('005167', '2026-05-08', 'Aprobada', 41816.73, 'INS-2026-04-008', 'CT-004402'),
  ('005168', '2026-05-08', 'Aprobada', 92306.94, 'INS-2026-04-009', 'CT-004589'),
  ('005169', '2026-05-08', 'Aprobada', 54618.20, 'INS-2026-04-010', 'CT-004608'),
  ('005170', '2026-05-09', 'Aprobada', 151066.17, 'INS-2026-04-011', 'CT-004455'),
  ('005171', '2026-05-09', 'Aprobada', 113192.44, 'INS-2026-04-012', 'CT-004517'),
  ('005172', '2026-05-09', 'Aprobada', 75422.33, 'INS-2026-04-013', 'CT-004532'),
  ('005173', '2026-05-09', 'Aprobada', 102266.55, 'INS-2026-04-014', 'CT-004655'),
  ('005174', '2026-05-09', 'Aprobada', 73323.83, 'INS-2026-04-015', 'CT-004719'),
  ('005175', '2026-06-02', 'Aprobada', 39965.46, 'INS-2026-05-001', 'CT-004402'),
  ('005176', '2026-06-02', 'Aprobada', 110643.14, 'INS-2026-05-002', 'CT-004517'),
  ('005177', '2026-06-02', 'Aprobada', 80817.14, 'INS-2026-05-003', 'CT-004532'),
  ('005178', '2026-06-02', 'Aprobada', 32865.20, 'INS-2026-05-004', 'CT-004671'),
  ('005179', '2026-06-03', 'Anulada', 29005.72, 'INS-2026-05-005', 'CT-004702'),
  ('005180', '2026-06-03', 'Aprobada', 70395.65, 'INS-2026-05-006', 'CT-004719'),
  ('005181', '2026-06-03', 'Aprobada', 72911.42, 'INS-2026-05-007', 'CT-004750'),
  ('005182', '2026-06-04', 'Aprobada', 146170.03, 'INS-2026-05-008', 'CT-004455'),
  ('005183', '2026-06-05', 'Aprobada', 102089.34, 'INS-2026-05-009', 'CT-004655'),
  ('005184', '2026-06-05', 'Aprobada', 44231.22, 'INS-2026-05-010', 'CT-004733'),
  ('005185', '2026-06-05', 'Aprobada', 51039.42, 'INS-2026-05-011', 'CT-004768'),
  ('005186', '2026-06-08', 'Aprobada', 46813.31, 'INS-2026-05-012', 'CT-004640'),
  ('005187', '2026-06-08', 'Aprobada', 21767.74, 'INS-2026-05-013', 'CT-004688'),
  ('005188', '2026-06-09', 'Aprobada', 49730.20, 'INS-2026-05-014', 'CT-004608'),
  ('005189', '2026-06-09', 'Aprobada', 29630.83, 'INS-2026-05-015', 'CT-004702'),
  ('005190', '2026-06-10', 'Aprobada', 88896.64, 'INS-2026-05-016', 'CT-004589'),
  ('005191', '2026-06-10', 'Aprobada', 138527.96, 'INS-2026-05-017', 'CT-004613'),
  ('005192', '2026-07-02', 'Aprobada', 39090.06, 'INS-2026-06-001', 'CT-004402'),
  ('005193', '2026-07-02', 'Aprobada', 73885.73, 'INS-2026-06-002', 'CT-004532'),
  ('005194', '2026-07-03', 'Aprobada', 117859.65, 'INS-2026-06-003', 'CT-004517'),
  ('005195', '2026-07-04', 'Aprobada', 52970.55, 'INS-2026-06-004', 'CT-004768'),
  ('005196', '2026-07-05', 'Aprobada', 151781.89, 'INS-2026-06-005', 'CT-004455'),
  ('005197', '2026-07-05', 'Aprobada', 94580.78, 'INS-2026-06-006', 'CT-004589'),
  ('005198', '2026-07-05', 'Aprobada', 50637.55, 'INS-2026-06-007', 'CT-004608'),
  ('005199', '2026-07-06', 'Aprobada', 132845.58, 'INS-2026-06-008', 'CT-004613'),
  ('005200', '2026-07-06', 'Aprobada', 47626.44, 'INS-2026-06-009', 'CT-004640'),
  ('005201', '2026-07-07', 'Aprobada', 28457.67, 'INS-2026-06-010', 'CT-004702'),
  ('005202', '2026-07-09', 'Aprobada', 21124.97, 'INS-2026-06-011', 'CT-004688'),
  ('005203', '2026-07-09', 'Aprobada', 47380.98, 'INS-2026-06-012', 'CT-004733'),
  ('005204', '2026-07-09', 'Aprobada', 71500.25, 'INS-2026-06-013', 'CT-004750'),
  ('005205', '2026-07-10', 'Aprobada', 102007.04, 'INS-2026-06-014', 'CT-004655'),
  ('005206', '2026-07-10', 'Aprobada', 31941.31, 'INS-2026-06-015', 'CT-004671'),
  ('005207', '2026-07-10', 'Aprobada', 72567.49, 'INS-2026-06-016', 'CT-004719'),
  ('005208', '2026-08-02', 'Aprobada', 140667.72, 'INS-2026-07-001', 'CT-004455'),
  ('005209', '2026-08-02', 'Aprobada', 57909.18, 'INS-2026-07-002', 'CT-004768'),
  ('005210', '2026-08-03', 'Aprobada', 40793.15, 'INS-2026-07-003', 'CT-004402'),
  ('005211', '2026-08-03', 'Aprobada', 136372.01, 'INS-2026-07-004', 'CT-004613'),
  ('005212', '2026-08-03', 'Aprobada', 105028.82, 'INS-2026-07-005', 'CT-004655'),
  ('005213', '2026-08-03', 'Aprobada', 46323.53, 'INS-2026-07-006', 'CT-004733'),
  ('005214', '2026-08-04', 'Pendiente', 117684.39, 'INS-2026-07-007', 'CT-004517'),
  ('005215', '2026-08-04', 'Aprobada', 77136.81, 'INS-2026-07-008', 'CT-004532'),
  ('005216', '2026-08-04', 'Aprobada', 90972.63, 'INS-2026-07-009', 'CT-004589'),
  ('005217', '2026-08-05', 'Pendiente', 32092.20, 'INS-2026-07-010', 'CT-004671'),
  ('005218', '2026-08-05', 'Aprobada', 30251.98, 'INS-2026-07-011', 'CT-004702'),
  ('005219', '2026-08-05', 'Aprobada', 68597.04, 'INS-2026-07-012', 'CT-004750');
INSERT INTO HES (Num_HES, Fecha_emision, Estado, Monto_servicio, Num_inspeccion, Num_contrato) VALUES
  ('005220', '2026-08-06', 'Aprobada', 48059.09, 'INS-2026-07-013', 'CT-004640'),
  ('005221', '2026-08-07', 'Aprobada', 54754.60, 'INS-2026-07-014', 'CT-004608'),
  ('005222', '2026-08-10', 'Pendiente', 21841.02, 'INS-2026-07-015', 'CT-004688'),
  ('005223', '2026-08-10', 'Pendiente', 74510.78, 'INS-2026-07-016', 'CT-004719'),
  ('005224', '2026-09-02', 'Aprobada', 28468.19, 'INS-2026-08-001', 'CT-004702'),
  ('005225', '2026-09-03', 'Aprobada', 73803.12, 'INS-2026-08-002', 'CT-004719'),
  ('005226', '2026-09-03', 'Aprobada', 43448.35, 'INS-2026-08-003', 'CT-004733'),
  ('005227', '2026-09-04', 'Aprobada', 123327.45, 'INS-2026-08-004', 'CT-004517'),
  ('005228', '2026-09-04', 'Aprobada', 49285.25, 'INS-2026-08-005', 'CT-004640'),
  ('005229', '2026-09-04', 'Aprobada', 70091.01, 'INS-2026-08-006', 'CT-004750'),
  ('005230', '2026-09-05', 'Aprobada', 38369.04, 'INS-2026-08-007', 'CT-004402'),
  ('005231', '2026-09-05', 'Aprobada', 137671.79, 'INS-2026-08-008', 'CT-004613'),
  ('005232', '2026-09-07', 'Aprobada', 133856.13, 'INS-2026-08-009', 'CT-004455'),
  ('005233', '2026-09-07', 'Aprobada', 82864.19, 'INS-2026-08-010', 'CT-004589'),
  ('005234', '2026-09-07', 'Aprobada', 53986.48, 'INS-2026-08-011', 'CT-004768'),
  ('005235', '2026-09-08', 'Aprobada', 112483.07, 'INS-2026-08-012', 'CT-004655'),
  ('005236', '2026-09-08', 'Aprobada', 30222.18, 'INS-2026-08-013', 'CT-004671'),
  ('005237', '2026-09-09', 'Pendiente', 74088.94, 'INS-2026-08-014', 'CT-004532'),
  ('005238', '2026-09-09', 'Aprobada', 54812.19, 'INS-2026-08-015', 'CT-004608'),
  ('005239', '2026-09-09', 'Aprobada', 21711.16, 'INS-2026-08-016', 'CT-004688'),
  ('005240', '2026-10-02', 'Aprobada', 46032.42, 'INS-2026-09-001', 'CT-004733'),
  ('005241', '2026-10-04', 'Aprobada', 41590.51, 'INS-2026-09-002', 'CT-004402'),
  ('005242', '2026-10-05', 'Pendiente', 31860.16, 'INS-2026-09-003', 'CT-004671'),
  ('005243', '2026-10-05', 'Aprobada', 29715.06, 'INS-2026-09-004', 'CT-004702'),
  ('005244', '2026-10-05', 'Aprobada', 68383.82, 'INS-2026-09-005', 'CT-004750'),
  ('005245', '2026-10-07', 'Pendiente', 53594.17, 'INS-2026-09-006', 'CT-004608'),
  ('005246', '2026-10-07', 'Pendiente', 130419.05, 'INS-2026-09-007', 'CT-004613'),
  ('005247', '2026-10-08', 'Pendiente', 82775.76, 'INS-2026-09-008', 'CT-004532'),
  ('005248', '2026-10-08', 'Pendiente', 87958.68, 'INS-2026-09-009', 'CT-004589'),
  ('005249', '2026-10-08', 'Pendiente', 46518.06, 'INS-2026-09-010', 'CT-004640'),
  ('005250', '2026-10-08', 'Pendiente', 23785.84, 'INS-2026-09-011', 'CT-004688'),
  ('005251', '2026-10-09', 'Pendiente', 121741.27, 'INS-2026-09-012', 'CT-004517'),
  ('005252', '2026-10-09', 'Pendiente', 69413.20, 'INS-2026-09-013', 'CT-004719'),
  ('005253', '2026-10-10', 'Pendiente', 114780.40, 'INS-2026-09-014', 'CT-004655'),
  ('005254', '2026-10-11', 'Pendiente', 147851.44, 'INS-2026-09-015', 'CT-004455'),
  ('005255', '2026-10-12', 'Pendiente', 51674.96, 'INS-2026-09-016', 'CT-004768');

-- OBSERVACION (16 filas)
INSERT INTO OBSERVACION (Num_HES, Num_observacion, Fecha_observacion, Comentario) VALUES
  ('005133', 1, '2026-03-09', 'Falta la constancia de pago de AFP Prima del periodo 02/2026.'),
  ('005133', 2, '2026-03-16', 'El monto declarado de ONP en el formato no coincide con el reporte de SUNAT.'),
  ('005150', 1, '2026-04-06', 'Los montos del formato no corresponden al periodo 03/2026; se rechaza la HES para su nueva emisión.'),
  ('005163', 1, '2026-05-11', 'El formato de inspección no consigna la fecha de pago de Vida Ley.'),
  ('005163', 2, '2026-05-18', 'Adjuntar la constancia del SCTR vigente para el periodo 04/2026.'),
  ('005214', 1, '2026-08-10', 'Falta la constancia de pago de AFP Prima del periodo 07/2026.'),
  ('005214', 2, '2026-08-24', 'El monto pagado de EsSalud en el formato no coincide con el reporte PLAME de SUNAT; corregir el formato.'),
  ('005214', 3, '2026-09-14', 'Persiste la diferencia en EsSalud y dos boletas de pago no están firmadas por los trabajadores.'),
  ('005217', 1, '2026-08-12', 'Faltan las boletas de pago del personal del periodo 07/2026 y la gratificación de julio figura pagada de forma parcial.'),
  ('005222', 1, '2026-08-13', 'El formato de inspección no está firmado por el representante de la contratista.'),
  ('005223', 1, '2026-08-11', 'Se registra mora en EsSalud; levantar la mora y presentar la declaración jurada con la fecha de pago.'),
  ('005223', 2, '2026-10-08', 'Venció la fecha comprometida en la declaración jurada; regularizar el pago de la mora de EsSalud.'),
  ('005237', 1, '2026-09-09', 'Se registra mora en el IGV; levantar la mora y presentar la declaración jurada.'),
  ('005249', 1, '2026-10-15', 'Falta la constancia del SCTR del periodo 09/2026 y una boleta de pago no está firmada.'),
  ('005253', 1, '2026-10-13', 'Se registra mora en Renta; levantar la mora y presentar la declaración jurada.'),
  ('005254', 1, '2026-10-14', 'Se registra mora en ONP; levantar la mora y presentar la declaración jurada con la fecha de pago.');

-- REPORTE_ENTIDAD (515 filas)
INSERT INTO REPORTE_ENTIDAD (Num_reporte, Cod_entidad, Num_inspeccion) VALUES
  ('REP-202601-0001', 1, 'INS-2026-01-001'),
  ('REP-202601-0002', 5, 'INS-2026-01-001'),
  ('REP-202601-0003', 10, 'INS-2026-01-001'),
  ('REP-202601-0004', 1, 'INS-2026-01-002'),
  ('REP-202601-0005', 4, 'INS-2026-01-002'),
  ('REP-202601-0006', 5, 'INS-2026-01-002'),
  ('REP-202601-0007', 8, 'INS-2026-01-002'),
  ('REP-202601-0008', 11, 'INS-2026-01-002'),
  ('REP-202601-0009', 1, 'INS-2026-01-003'),
  ('REP-202601-0010', 4, 'INS-2026-01-003'),
  ('REP-202601-0011', 7, 'INS-2026-01-003'),
  ('REP-202601-0012', 8, 'INS-2026-01-003'),
  ('REP-202601-0013', 12, 'INS-2026-01-003'),
  ('REP-202601-0014', 1, 'INS-2026-01-004'),
  ('REP-202601-0015', 7, 'INS-2026-01-004'),
  ('REP-202601-0016', 4, 'INS-2026-01-004'),
  ('REP-202601-0017', 9, 'INS-2026-01-004'),
  ('REP-202601-0018', 1, 'INS-2026-01-005'),
  ('REP-202601-0019', 4, 'INS-2026-01-005'),
  ('REP-202601-0020', 8, 'INS-2026-01-005'),
  ('REP-202601-0021', 1, 'INS-2026-01-006'),
  ('REP-202601-0022', 5, 'INS-2026-01-006'),
  ('REP-202601-0023', 6, 'INS-2026-01-006'),
  ('REP-202601-0024', 10, 'INS-2026-01-006'),
  ('REP-202601-0025', 1, 'INS-2026-01-007'),
  ('REP-202601-0026', 4, 'INS-2026-01-007'),
  ('REP-202601-0027', 5, 'INS-2026-01-007'),
  ('REP-202601-0028', 9, 'INS-2026-01-007'),
  ('REP-202601-0029', 1, 'INS-2026-01-008'),
  ('REP-202601-0030', 5, 'INS-2026-01-008'),
  ('REP-202601-0031', 6, 'INS-2026-01-008'),
  ('REP-202601-0032', 10, 'INS-2026-01-008'),
  ('REP-202601-0033', 1, 'INS-2026-01-009'),
  ('REP-202601-0034', 4, 'INS-2026-01-009'),
  ('REP-202601-0035', 9, 'INS-2026-01-009'),
  ('REP-202601-0036', 1, 'INS-2026-01-010'),
  ('REP-202601-0037', 4, 'INS-2026-01-010'),
  ('REP-202601-0038', 5, 'INS-2026-01-010'),
  ('REP-202601-0039', 9, 'INS-2026-01-010'),
  ('REP-202601-0040', 1, 'INS-2026-01-011'),
  ('REP-202601-0041', 6, 'INS-2026-01-011'),
  ('REP-202601-0042', 8, 'INS-2026-01-011'),
  ('REP-202602-0001', 1, 'INS-2026-02-001'),
  ('REP-202602-0002', 4, 'INS-2026-02-001'),
  ('REP-202602-0003', 9, 'INS-2026-02-001'),
  ('REP-202602-0004', 1, 'INS-2026-02-002'),
  ('REP-202602-0005', 4, 'INS-2026-02-002'),
  ('REP-202602-0006', 5, 'INS-2026-02-002'),
  ('REP-202602-0007', 8, 'INS-2026-02-002'),
  ('REP-202602-0008', 11, 'INS-2026-02-002'),
  ('REP-202602-0009', 1, 'INS-2026-02-003'),
  ('REP-202602-0010', 5, 'INS-2026-02-003'),
  ('REP-202602-0011', 10, 'INS-2026-02-003'),
  ('REP-202602-0012', 1, 'INS-2026-02-004'),
  ('REP-202602-0013', 5, 'INS-2026-02-004'),
  ('REP-202602-0014', 6, 'INS-2026-02-004'),
  ('REP-202602-0015', 10, 'INS-2026-02-004'),
  ('REP-202602-0016', 1, 'INS-2026-02-005'),
  ('REP-202602-0017', 4, 'INS-2026-02-005'),
  ('REP-202602-0018', 5, 'INS-2026-02-005'),
  ('REP-202602-0019', 8, 'INS-2026-02-005'),
  ('REP-202602-0020', 11, 'INS-2026-02-005'),
  ('REP-202602-0021', 1, 'INS-2026-02-006'),
  ('REP-202602-0022', 7, 'INS-2026-02-006'),
  ('REP-202602-0023', 10, 'INS-2026-02-006'),
  ('REP-202602-0024', 11, 'INS-2026-02-006'),
  ('REP-202602-0025', 1, 'INS-2026-02-007'),
  ('REP-202602-0026', 6, 'INS-2026-02-007'),
  ('REP-202602-0027', 8, 'INS-2026-02-007'),
  ('REP-202602-0028', 1, 'INS-2026-02-008'),
  ('REP-202602-0029', 4, 'INS-2026-02-008'),
  ('REP-202602-0030', 8, 'INS-2026-02-008'),
  ('REP-202602-0031', 1, 'INS-2026-02-009'),
  ('REP-202602-0032', 7, 'INS-2026-02-009'),
  ('REP-202602-0033', 4, 'INS-2026-02-009'),
  ('REP-202602-0034', 9, 'INS-2026-02-009'),
  ('REP-202602-0035', 1, 'INS-2026-02-010'),
  ('REP-202602-0036', 4, 'INS-2026-02-010'),
  ('REP-202602-0037', 5, 'INS-2026-02-010'),
  ('REP-202602-0038', 9, 'INS-2026-02-010'),
  ('REP-202602-0039', 1, 'INS-2026-02-011'),
  ('REP-202602-0040', 4, 'INS-2026-02-011'),
  ('REP-202602-0041', 7, 'INS-2026-02-011'),
  ('REP-202602-0042', 8, 'INS-2026-02-011'),
  ('REP-202602-0043', 12, 'INS-2026-02-011'),
  ('REP-202602-0044', 1, 'INS-2026-02-012'),
  ('REP-202602-0045', 4, 'INS-2026-02-012'),
  ('REP-202602-0046', 5, 'INS-2026-02-012'),
  ('REP-202602-0047', 9, 'INS-2026-02-012'),
  ('REP-202602-0048', 1, 'INS-2026-02-013'),
  ('REP-202602-0049', 5, 'INS-2026-02-013'),
  ('REP-202602-0050', 6, 'INS-2026-02-013'),
  ('REP-202602-0051', 10, 'INS-2026-02-013'),
  ('REP-202602-0052', 1, 'INS-2026-02-014'),
  ('REP-202602-0053', 7, 'INS-2026-02-014'),
  ('REP-202602-0054', 10, 'INS-2026-02-014'),
  ('REP-202602-0055', 11, 'INS-2026-02-014'),
  ('REP-202603-0001', 1, 'INS-2026-03-001'),
  ('REP-202603-0002', 4, 'INS-2026-03-001'),
  ('REP-202603-0003', 5, 'INS-2026-03-001');
INSERT INTO REPORTE_ENTIDAD (Num_reporte, Cod_entidad, Num_inspeccion) VALUES
  ('REP-202603-0004', 9, 'INS-2026-03-001'),
  ('REP-202603-0005', 1, 'INS-2026-03-002'),
  ('REP-202603-0006', 4, 'INS-2026-03-002'),
  ('REP-202603-0007', 7, 'INS-2026-03-002'),
  ('REP-202603-0008', 8, 'INS-2026-03-002'),
  ('REP-202603-0009', 12, 'INS-2026-03-002'),
  ('REP-202603-0010', 1, 'INS-2026-03-003'),
  ('REP-202603-0011', 5, 'INS-2026-03-003'),
  ('REP-202603-0012', 8, 'INS-2026-03-003'),
  ('REP-202603-0013', 1, 'INS-2026-03-004'),
  ('REP-202603-0014', 4, 'INS-2026-03-004'),
  ('REP-202603-0015', 8, 'INS-2026-03-004'),
  ('REP-202603-0016', 1, 'INS-2026-03-005'),
  ('REP-202603-0017', 4, 'INS-2026-03-005'),
  ('REP-202603-0018', 5, 'INS-2026-03-005'),
  ('REP-202603-0019', 8, 'INS-2026-03-005'),
  ('REP-202603-0020', 11, 'INS-2026-03-005'),
  ('REP-202603-0021', 1, 'INS-2026-03-006'),
  ('REP-202603-0022', 7, 'INS-2026-03-006'),
  ('REP-202603-0023', 4, 'INS-2026-03-006'),
  ('REP-202603-0024', 9, 'INS-2026-03-006'),
  ('REP-202603-0025', 1, 'INS-2026-03-007'),
  ('REP-202603-0026', 5, 'INS-2026-03-007'),
  ('REP-202603-0027', 6, 'INS-2026-03-007'),
  ('REP-202603-0028', 10, 'INS-2026-03-007'),
  ('REP-202603-0029', 1, 'INS-2026-03-008'),
  ('REP-202603-0030', 6, 'INS-2026-03-008'),
  ('REP-202603-0031', 8, 'INS-2026-03-008'),
  ('REP-202603-0032', 1, 'INS-2026-03-009'),
  ('REP-202603-0033', 7, 'INS-2026-03-009'),
  ('REP-202603-0034', 10, 'INS-2026-03-009'),
  ('REP-202603-0035', 11, 'INS-2026-03-009'),
  ('REP-202603-0036', 1, 'INS-2026-03-010'),
  ('REP-202603-0037', 4, 'INS-2026-03-010'),
  ('REP-202603-0038', 5, 'INS-2026-03-010'),
  ('REP-202603-0039', 9, 'INS-2026-03-010'),
  ('REP-202603-0040', 1, 'INS-2026-03-011'),
  ('REP-202603-0041', 5, 'INS-2026-03-011'),
  ('REP-202603-0042', 10, 'INS-2026-03-011'),
  ('REP-202603-0043', 1, 'INS-2026-03-012'),
  ('REP-202603-0044', 4, 'INS-2026-03-012'),
  ('REP-202603-0045', 9, 'INS-2026-03-012'),
  ('REP-202603-0046', 1, 'INS-2026-03-013'),
  ('REP-202603-0047', 4, 'INS-2026-03-013'),
  ('REP-202603-0048', 5, 'INS-2026-03-013'),
  ('REP-202603-0049', 8, 'INS-2026-03-013'),
  ('REP-202603-0050', 11, 'INS-2026-03-013'),
  ('REP-202603-0051', 1, 'INS-2026-03-014'),
  ('REP-202603-0052', 5, 'INS-2026-03-014'),
  ('REP-202603-0053', 6, 'INS-2026-03-014'),
  ('REP-202603-0054', 10, 'INS-2026-03-014'),
  ('REP-202603-0055', 1, 'INS-2026-03-015'),
  ('REP-202603-0056', 7, 'INS-2026-03-015'),
  ('REP-202603-0057', 4, 'INS-2026-03-015'),
  ('REP-202603-0058', 9, 'INS-2026-03-015'),
  ('REP-202604-0001', 1, 'INS-2026-04-001'),
  ('REP-202604-0002', 5, 'INS-2026-04-001'),
  ('REP-202604-0003', 8, 'INS-2026-04-001'),
  ('REP-202604-0004', 1, 'INS-2026-04-002'),
  ('REP-202604-0005', 7, 'INS-2026-04-002'),
  ('REP-202604-0006', 10, 'INS-2026-04-002'),
  ('REP-202604-0007', 11, 'INS-2026-04-002'),
  ('REP-202604-0008', 1, 'INS-2026-04-003'),
  ('REP-202604-0009', 4, 'INS-2026-04-003'),
  ('REP-202604-0010', 5, 'INS-2026-04-003'),
  ('REP-202604-0011', 9, 'INS-2026-04-003'),
  ('REP-202604-0012', 1, 'INS-2026-04-004'),
  ('REP-202604-0013', 4, 'INS-2026-04-004'),
  ('REP-202604-0014', 9, 'INS-2026-04-004'),
  ('REP-202604-0015', 1, 'INS-2026-04-005'),
  ('REP-202604-0016', 5, 'INS-2026-04-005'),
  ('REP-202604-0017', 9, 'INS-2026-04-005'),
  ('REP-202604-0018', 1, 'INS-2026-04-006'),
  ('REP-202604-0019', 4, 'INS-2026-04-006'),
  ('REP-202604-0020', 8, 'INS-2026-04-006'),
  ('REP-202604-0021', 1, 'INS-2026-04-007'),
  ('REP-202604-0022', 5, 'INS-2026-04-007'),
  ('REP-202604-0023', 6, 'INS-2026-04-007'),
  ('REP-202604-0024', 10, 'INS-2026-04-007'),
  ('REP-202604-0025', 1, 'INS-2026-04-008'),
  ('REP-202604-0026', 5, 'INS-2026-04-008'),
  ('REP-202604-0027', 10, 'INS-2026-04-008'),
  ('REP-202604-0028', 1, 'INS-2026-04-009'),
  ('REP-202604-0029', 6, 'INS-2026-04-009'),
  ('REP-202604-0030', 8, 'INS-2026-04-009'),
  ('REP-202604-0031', 1, 'INS-2026-04-010'),
  ('REP-202604-0032', 4, 'INS-2026-04-010'),
  ('REP-202604-0033', 5, 'INS-2026-04-010'),
  ('REP-202604-0034', 9, 'INS-2026-04-010'),
  ('REP-202604-0035', 1, 'INS-2026-04-011'),
  ('REP-202604-0036', 7, 'INS-2026-04-011'),
  ('REP-202604-0037', 4, 'INS-2026-04-011'),
  ('REP-202604-0038', 9, 'INS-2026-04-011'),
  ('REP-202604-0039', 1, 'INS-2026-04-012'),
  ('REP-202604-0040', 4, 'INS-2026-04-012'),
  ('REP-202604-0041', 5, 'INS-2026-04-012'),
  ('REP-202604-0042', 8, 'INS-2026-04-012'),
  ('REP-202604-0043', 11, 'INS-2026-04-012'),
  ('REP-202604-0044', 1, 'INS-2026-04-013'),
  ('REP-202604-0045', 5, 'INS-2026-04-013');
INSERT INTO REPORTE_ENTIDAD (Num_reporte, Cod_entidad, Num_inspeccion) VALUES
  ('REP-202604-0046', 6, 'INS-2026-04-013'),
  ('REP-202604-0047', 10, 'INS-2026-04-013'),
  ('REP-202604-0048', 1, 'INS-2026-04-014'),
  ('REP-202604-0049', 4, 'INS-2026-04-014'),
  ('REP-202604-0050', 7, 'INS-2026-04-014'),
  ('REP-202604-0051', 8, 'INS-2026-04-014'),
  ('REP-202604-0052', 12, 'INS-2026-04-014'),
  ('REP-202604-0053', 1, 'INS-2026-04-015'),
  ('REP-202604-0054', 4, 'INS-2026-04-015'),
  ('REP-202604-0055', 5, 'INS-2026-04-015'),
  ('REP-202604-0056', 8, 'INS-2026-04-015'),
  ('REP-202604-0057', 11, 'INS-2026-04-015'),
  ('REP-202605-0001', 1, 'INS-2026-05-001'),
  ('REP-202605-0002', 5, 'INS-2026-05-001'),
  ('REP-202605-0003', 10, 'INS-2026-05-001'),
  ('REP-202605-0004', 1, 'INS-2026-05-002'),
  ('REP-202605-0005', 4, 'INS-2026-05-002'),
  ('REP-202605-0006', 5, 'INS-2026-05-002'),
  ('REP-202605-0007', 8, 'INS-2026-05-002'),
  ('REP-202605-0008', 11, 'INS-2026-05-002'),
  ('REP-202605-0009', 1, 'INS-2026-05-003'),
  ('REP-202605-0010', 5, 'INS-2026-05-003'),
  ('REP-202605-0011', 6, 'INS-2026-05-003'),
  ('REP-202605-0012', 10, 'INS-2026-05-003'),
  ('REP-202605-0013', 1, 'INS-2026-05-004'),
  ('REP-202605-0014', 5, 'INS-2026-05-004'),
  ('REP-202605-0015', 8, 'INS-2026-05-004'),
  ('REP-202605-0016', 1, 'INS-2026-05-005'),
  ('REP-202605-0017', 4, 'INS-2026-05-005'),
  ('REP-202605-0018', 8, 'INS-2026-05-005'),
  ('REP-202605-0019', 1, 'INS-2026-05-006'),
  ('REP-202605-0020', 4, 'INS-2026-05-006'),
  ('REP-202605-0021', 5, 'INS-2026-05-006'),
  ('REP-202605-0022', 8, 'INS-2026-05-006'),
  ('REP-202605-0023', 11, 'INS-2026-05-006'),
  ('REP-202605-0024', 1, 'INS-2026-05-007'),
  ('REP-202605-0025', 5, 'INS-2026-05-007'),
  ('REP-202605-0026', 6, 'INS-2026-05-007'),
  ('REP-202605-0027', 10, 'INS-2026-05-007'),
  ('REP-202605-0028', 1, 'INS-2026-05-008'),
  ('REP-202605-0029', 7, 'INS-2026-05-008'),
  ('REP-202605-0030', 4, 'INS-2026-05-008'),
  ('REP-202605-0031', 9, 'INS-2026-05-008'),
  ('REP-202605-0032', 1, 'INS-2026-05-009'),
  ('REP-202605-0033', 4, 'INS-2026-05-009'),
  ('REP-202605-0034', 7, 'INS-2026-05-009'),
  ('REP-202605-0035', 8, 'INS-2026-05-009'),
  ('REP-202605-0036', 12, 'INS-2026-05-009'),
  ('REP-202605-0037', 1, 'INS-2026-05-010'),
  ('REP-202605-0038', 4, 'INS-2026-05-010'),
  ('REP-202605-0039', 5, 'INS-2026-05-010'),
  ('REP-202605-0040', 9, 'INS-2026-05-010'),
  ('REP-202605-0041', 1, 'INS-2026-05-011'),
  ('REP-202605-0042', 6, 'INS-2026-05-011'),
  ('REP-202605-0043', 8, 'INS-2026-05-011'),
  ('REP-202605-0044', 1, 'INS-2026-05-012'),
  ('REP-202605-0045', 4, 'INS-2026-05-012'),
  ('REP-202605-0046', 9, 'INS-2026-05-012'),
  ('REP-202605-0047', 1, 'INS-2026-05-013'),
  ('REP-202605-0048', 5, 'INS-2026-05-013'),
  ('REP-202605-0049', 9, 'INS-2026-05-013'),
  ('REP-202605-0050', 1, 'INS-2026-05-014'),
  ('REP-202605-0051', 4, 'INS-2026-05-014'),
  ('REP-202605-0052', 5, 'INS-2026-05-014'),
  ('REP-202605-0053', 9, 'INS-2026-05-014'),
  ('REP-202605-0054', 1, 'INS-2026-05-015'),
  ('REP-202605-0055', 4, 'INS-2026-05-015'),
  ('REP-202605-0056', 8, 'INS-2026-05-015'),
  ('REP-202605-0057', 1, 'INS-2026-05-016'),
  ('REP-202605-0058', 6, 'INS-2026-05-016'),
  ('REP-202605-0059', 8, 'INS-2026-05-016'),
  ('REP-202605-0060', 1, 'INS-2026-05-017'),
  ('REP-202605-0061', 7, 'INS-2026-05-017'),
  ('REP-202605-0062', 10, 'INS-2026-05-017'),
  ('REP-202605-0063', 11, 'INS-2026-05-017'),
  ('REP-202606-0001', 1, 'INS-2026-06-001'),
  ('REP-202606-0002', 5, 'INS-2026-06-001'),
  ('REP-202606-0003', 10, 'INS-2026-06-001'),
  ('REP-202606-0004', 1, 'INS-2026-06-002'),
  ('REP-202606-0005', 5, 'INS-2026-06-002'),
  ('REP-202606-0006', 6, 'INS-2026-06-002'),
  ('REP-202606-0007', 10, 'INS-2026-06-002'),
  ('REP-202606-0008', 1, 'INS-2026-06-003'),
  ('REP-202606-0009', 4, 'INS-2026-06-003'),
  ('REP-202606-0010', 5, 'INS-2026-06-003'),
  ('REP-202606-0011', 8, 'INS-2026-06-003'),
  ('REP-202606-0012', 11, 'INS-2026-06-003'),
  ('REP-202606-0013', 1, 'INS-2026-06-004'),
  ('REP-202606-0014', 6, 'INS-2026-06-004'),
  ('REP-202606-0015', 8, 'INS-2026-06-004'),
  ('REP-202606-0016', 1, 'INS-2026-06-005'),
  ('REP-202606-0017', 7, 'INS-2026-06-005'),
  ('REP-202606-0018', 4, 'INS-2026-06-005'),
  ('REP-202606-0019', 9, 'INS-2026-06-005'),
  ('REP-202606-0020', 1, 'INS-2026-06-006'),
  ('REP-202606-0021', 6, 'INS-2026-06-006'),
  ('REP-202606-0022', 8, 'INS-2026-06-006'),
  ('REP-202606-0023', 1, 'INS-2026-06-007'),
  ('REP-202606-0024', 4, 'INS-2026-06-007'),
  ('REP-202606-0025', 5, 'INS-2026-06-007');
INSERT INTO REPORTE_ENTIDAD (Num_reporte, Cod_entidad, Num_inspeccion) VALUES
  ('REP-202606-0026', 9, 'INS-2026-06-007'),
  ('REP-202606-0027', 1, 'INS-2026-06-008'),
  ('REP-202606-0028', 7, 'INS-2026-06-008'),
  ('REP-202606-0029', 10, 'INS-2026-06-008'),
  ('REP-202606-0030', 11, 'INS-2026-06-008'),
  ('REP-202606-0031', 1, 'INS-2026-06-009'),
  ('REP-202606-0032', 4, 'INS-2026-06-009'),
  ('REP-202606-0033', 9, 'INS-2026-06-009'),
  ('REP-202606-0034', 1, 'INS-2026-06-010'),
  ('REP-202606-0035', 4, 'INS-2026-06-010'),
  ('REP-202606-0036', 8, 'INS-2026-06-010'),
  ('REP-202606-0037', 1, 'INS-2026-06-011'),
  ('REP-202606-0038', 5, 'INS-2026-06-011'),
  ('REP-202606-0039', 9, 'INS-2026-06-011'),
  ('REP-202606-0040', 1, 'INS-2026-06-012'),
  ('REP-202606-0041', 4, 'INS-2026-06-012'),
  ('REP-202606-0042', 5, 'INS-2026-06-012'),
  ('REP-202606-0043', 9, 'INS-2026-06-012'),
  ('REP-202606-0044', 1, 'INS-2026-06-013'),
  ('REP-202606-0045', 5, 'INS-2026-06-013'),
  ('REP-202606-0046', 6, 'INS-2026-06-013'),
  ('REP-202606-0047', 10, 'INS-2026-06-013'),
  ('REP-202606-0048', 1, 'INS-2026-06-014'),
  ('REP-202606-0049', 4, 'INS-2026-06-014'),
  ('REP-202606-0050', 7, 'INS-2026-06-014'),
  ('REP-202606-0051', 8, 'INS-2026-06-014'),
  ('REP-202606-0052', 12, 'INS-2026-06-014'),
  ('REP-202606-0053', 1, 'INS-2026-06-015'),
  ('REP-202606-0054', 5, 'INS-2026-06-015'),
  ('REP-202606-0055', 8, 'INS-2026-06-015'),
  ('REP-202606-0056', 1, 'INS-2026-06-016'),
  ('REP-202606-0057', 4, 'INS-2026-06-016'),
  ('REP-202606-0058', 5, 'INS-2026-06-016'),
  ('REP-202606-0059', 8, 'INS-2026-06-016'),
  ('REP-202606-0060', 11, 'INS-2026-06-016'),
  ('REP-202607-0001', 1, 'INS-2026-07-001'),
  ('REP-202607-0002', 7, 'INS-2026-07-001'),
  ('REP-202607-0003', 4, 'INS-2026-07-001'),
  ('REP-202607-0004', 9, 'INS-2026-07-001'),
  ('REP-202607-0005', 1, 'INS-2026-07-002'),
  ('REP-202607-0006', 6, 'INS-2026-07-002'),
  ('REP-202607-0007', 8, 'INS-2026-07-002'),
  ('REP-202607-0008', 1, 'INS-2026-07-003'),
  ('REP-202607-0009', 5, 'INS-2026-07-003'),
  ('REP-202607-0010', 10, 'INS-2026-07-003'),
  ('REP-202607-0011', 1, 'INS-2026-07-004'),
  ('REP-202607-0012', 7, 'INS-2026-07-004'),
  ('REP-202607-0013', 10, 'INS-2026-07-004'),
  ('REP-202607-0014', 11, 'INS-2026-07-004'),
  ('REP-202607-0015', 1, 'INS-2026-07-005'),
  ('REP-202607-0016', 4, 'INS-2026-07-005'),
  ('REP-202607-0017', 7, 'INS-2026-07-005'),
  ('REP-202607-0018', 8, 'INS-2026-07-005'),
  ('REP-202607-0019', 12, 'INS-2026-07-005'),
  ('REP-202607-0020', 1, 'INS-2026-07-006'),
  ('REP-202607-0021', 4, 'INS-2026-07-006'),
  ('REP-202607-0022', 5, 'INS-2026-07-006'),
  ('REP-202607-0023', 9, 'INS-2026-07-006'),
  ('REP-202607-0024', 1, 'INS-2026-07-007'),
  ('REP-202607-0025', 4, 'INS-2026-07-007'),
  ('REP-202607-0026', 5, 'INS-2026-07-007'),
  ('REP-202607-0027', 8, 'INS-2026-07-007'),
  ('REP-202607-0028', 11, 'INS-2026-07-007'),
  ('REP-202607-0029', 1, 'INS-2026-07-008'),
  ('REP-202607-0030', 5, 'INS-2026-07-008'),
  ('REP-202607-0031', 6, 'INS-2026-07-008'),
  ('REP-202607-0032', 10, 'INS-2026-07-008'),
  ('REP-202607-0033', 1, 'INS-2026-07-009'),
  ('REP-202607-0034', 6, 'INS-2026-07-009'),
  ('REP-202607-0035', 8, 'INS-2026-07-009'),
  ('REP-202607-0036', 1, 'INS-2026-07-010'),
  ('REP-202607-0037', 5, 'INS-2026-07-010'),
  ('REP-202607-0038', 8, 'INS-2026-07-010'),
  ('REP-202607-0039', 1, 'INS-2026-07-011'),
  ('REP-202607-0040', 4, 'INS-2026-07-011'),
  ('REP-202607-0041', 8, 'INS-2026-07-011'),
  ('REP-202607-0042', 1, 'INS-2026-07-012'),
  ('REP-202607-0043', 5, 'INS-2026-07-012'),
  ('REP-202607-0044', 6, 'INS-2026-07-012'),
  ('REP-202607-0045', 10, 'INS-2026-07-012'),
  ('REP-202607-0046', 1, 'INS-2026-07-013'),
  ('REP-202607-0047', 4, 'INS-2026-07-013'),
  ('REP-202607-0048', 9, 'INS-2026-07-013'),
  ('REP-202607-0049', 1, 'INS-2026-07-014'),
  ('REP-202607-0050', 4, 'INS-2026-07-014'),
  ('REP-202607-0051', 5, 'INS-2026-07-014'),
  ('REP-202607-0052', 9, 'INS-2026-07-014'),
  ('REP-202607-0053', 1, 'INS-2026-07-015'),
  ('REP-202607-0054', 5, 'INS-2026-07-015'),
  ('REP-202607-0055', 9, 'INS-2026-07-015'),
  ('REP-202607-0056', 1, 'INS-2026-07-016'),
  ('REP-202607-0057', 4, 'INS-2026-07-016'),
  ('REP-202607-0058', 5, 'INS-2026-07-016'),
  ('REP-202607-0059', 8, 'INS-2026-07-016'),
  ('REP-202607-0060', 11, 'INS-2026-07-016'),
  ('REP-202608-0001', 1, 'INS-2026-08-001'),
  ('REP-202608-0002', 4, 'INS-2026-08-001'),
  ('REP-202608-0003', 8, 'INS-2026-08-001'),
  ('REP-202608-0004', 1, 'INS-2026-08-002'),
  ('REP-202608-0005', 4, 'INS-2026-08-002');
INSERT INTO REPORTE_ENTIDAD (Num_reporte, Cod_entidad, Num_inspeccion) VALUES
  ('REP-202608-0006', 5, 'INS-2026-08-002'),
  ('REP-202608-0007', 8, 'INS-2026-08-002'),
  ('REP-202608-0008', 11, 'INS-2026-08-002'),
  ('REP-202608-0009', 1, 'INS-2026-08-003'),
  ('REP-202608-0010', 4, 'INS-2026-08-003'),
  ('REP-202608-0011', 5, 'INS-2026-08-003'),
  ('REP-202608-0012', 9, 'INS-2026-08-003'),
  ('REP-202608-0013', 1, 'INS-2026-08-004'),
  ('REP-202608-0014', 4, 'INS-2026-08-004'),
  ('REP-202608-0015', 5, 'INS-2026-08-004'),
  ('REP-202608-0016', 8, 'INS-2026-08-004'),
  ('REP-202608-0017', 11, 'INS-2026-08-004'),
  ('REP-202608-0018', 1, 'INS-2026-08-005'),
  ('REP-202608-0019', 4, 'INS-2026-08-005'),
  ('REP-202608-0020', 9, 'INS-2026-08-005'),
  ('REP-202608-0021', 1, 'INS-2026-08-006'),
  ('REP-202608-0022', 5, 'INS-2026-08-006'),
  ('REP-202608-0023', 6, 'INS-2026-08-006'),
  ('REP-202608-0024', 10, 'INS-2026-08-006'),
  ('REP-202608-0025', 1, 'INS-2026-08-007'),
  ('REP-202608-0026', 5, 'INS-2026-08-007'),
  ('REP-202608-0027', 10, 'INS-2026-08-007'),
  ('REP-202608-0028', 1, 'INS-2026-08-008'),
  ('REP-202608-0029', 7, 'INS-2026-08-008'),
  ('REP-202608-0030', 10, 'INS-2026-08-008'),
  ('REP-202608-0031', 11, 'INS-2026-08-008'),
  ('REP-202608-0032', 1, 'INS-2026-08-009'),
  ('REP-202608-0033', 7, 'INS-2026-08-009'),
  ('REP-202608-0034', 4, 'INS-2026-08-009'),
  ('REP-202608-0035', 9, 'INS-2026-08-009'),
  ('REP-202608-0036', 1, 'INS-2026-08-010'),
  ('REP-202608-0037', 6, 'INS-2026-08-010'),
  ('REP-202608-0038', 8, 'INS-2026-08-010'),
  ('REP-202608-0039', 1, 'INS-2026-08-011'),
  ('REP-202608-0040', 6, 'INS-2026-08-011'),
  ('REP-202608-0041', 8, 'INS-2026-08-011'),
  ('REP-202608-0042', 1, 'INS-2026-08-012'),
  ('REP-202608-0043', 4, 'INS-2026-08-012'),
  ('REP-202608-0044', 7, 'INS-2026-08-012'),
  ('REP-202608-0045', 8, 'INS-2026-08-012'),
  ('REP-202608-0046', 12, 'INS-2026-08-012'),
  ('REP-202608-0047', 1, 'INS-2026-08-013'),
  ('REP-202608-0048', 5, 'INS-2026-08-013'),
  ('REP-202608-0049', 8, 'INS-2026-08-013'),
  ('REP-202608-0050', 1, 'INS-2026-08-014'),
  ('REP-202608-0051', 5, 'INS-2026-08-014'),
  ('REP-202608-0052', 6, 'INS-2026-08-014'),
  ('REP-202608-0053', 10, 'INS-2026-08-014'),
  ('REP-202608-0054', 1, 'INS-2026-08-015'),
  ('REP-202608-0055', 4, 'INS-2026-08-015'),
  ('REP-202608-0056', 5, 'INS-2026-08-015'),
  ('REP-202608-0057', 9, 'INS-2026-08-015'),
  ('REP-202608-0058', 1, 'INS-2026-08-016'),
  ('REP-202608-0059', 5, 'INS-2026-08-016'),
  ('REP-202608-0060', 9, 'INS-2026-08-016'),
  ('REP-202609-0001', 1, 'INS-2026-09-001'),
  ('REP-202609-0002', 4, 'INS-2026-09-001'),
  ('REP-202609-0003', 5, 'INS-2026-09-001'),
  ('REP-202609-0004', 9, 'INS-2026-09-001'),
  ('REP-202609-0005', 1, 'INS-2026-09-002'),
  ('REP-202609-0006', 5, 'INS-2026-09-002'),
  ('REP-202609-0007', 10, 'INS-2026-09-002'),
  ('REP-202609-0008', 1, 'INS-2026-09-003'),
  ('REP-202609-0009', 5, 'INS-2026-09-003'),
  ('REP-202609-0010', 8, 'INS-2026-09-003'),
  ('REP-202609-0011', 1, 'INS-2026-09-004'),
  ('REP-202609-0012', 4, 'INS-2026-09-004'),
  ('REP-202609-0013', 8, 'INS-2026-09-004'),
  ('REP-202609-0014', 1, 'INS-2026-09-005'),
  ('REP-202609-0015', 5, 'INS-2026-09-005'),
  ('REP-202609-0016', 6, 'INS-2026-09-005'),
  ('REP-202609-0017', 10, 'INS-2026-09-005'),
  ('REP-202609-0018', 1, 'INS-2026-09-006'),
  ('REP-202609-0019', 4, 'INS-2026-09-006'),
  ('REP-202609-0020', 5, 'INS-2026-09-006'),
  ('REP-202609-0021', 9, 'INS-2026-09-006'),
  ('REP-202609-0022', 1, 'INS-2026-09-007'),
  ('REP-202609-0023', 7, 'INS-2026-09-007'),
  ('REP-202609-0024', 10, 'INS-2026-09-007'),
  ('REP-202609-0025', 11, 'INS-2026-09-007'),
  ('REP-202609-0026', 1, 'INS-2026-09-008'),
  ('REP-202609-0027', 5, 'INS-2026-09-008'),
  ('REP-202609-0028', 6, 'INS-2026-09-008'),
  ('REP-202609-0029', 10, 'INS-2026-09-008'),
  ('REP-202609-0030', 1, 'INS-2026-09-009'),
  ('REP-202609-0031', 6, 'INS-2026-09-009'),
  ('REP-202609-0032', 8, 'INS-2026-09-009'),
  ('REP-202609-0033', 1, 'INS-2026-09-010'),
  ('REP-202609-0034', 4, 'INS-2026-09-010'),
  ('REP-202609-0035', 9, 'INS-2026-09-010'),
  ('REP-202609-0036', 1, 'INS-2026-09-011'),
  ('REP-202609-0037', 5, 'INS-2026-09-011'),
  ('REP-202609-0038', 9, 'INS-2026-09-011'),
  ('REP-202609-0039', 1, 'INS-2026-09-012'),
  ('REP-202609-0040', 4, 'INS-2026-09-012'),
  ('REP-202609-0041', 5, 'INS-2026-09-012'),
  ('REP-202609-0042', 8, 'INS-2026-09-012'),
  ('REP-202609-0043', 11, 'INS-2026-09-012'),
  ('REP-202609-0044', 1, 'INS-2026-09-013'),
  ('REP-202609-0045', 4, 'INS-2026-09-013');
INSERT INTO REPORTE_ENTIDAD (Num_reporte, Cod_entidad, Num_inspeccion) VALUES
  ('REP-202609-0046', 5, 'INS-2026-09-013'),
  ('REP-202609-0047', 8, 'INS-2026-09-013'),
  ('REP-202609-0048', 11, 'INS-2026-09-013'),
  ('REP-202609-0049', 1, 'INS-2026-09-014'),
  ('REP-202609-0050', 4, 'INS-2026-09-014'),
  ('REP-202609-0051', 7, 'INS-2026-09-014'),
  ('REP-202609-0052', 8, 'INS-2026-09-014'),
  ('REP-202609-0053', 12, 'INS-2026-09-014'),
  ('REP-202609-0054', 1, 'INS-2026-09-015'),
  ('REP-202609-0055', 7, 'INS-2026-09-015'),
  ('REP-202609-0056', 4, 'INS-2026-09-015'),
  ('REP-202609-0057', 9, 'INS-2026-09-015'),
  ('REP-202609-0058', 1, 'INS-2026-09-016'),
  ('REP-202609-0059', 6, 'INS-2026-09-016'),
  ('REP-202609-0060', 8, 'INS-2026-09-016');

-- BOLETA_PAGO (886 filas)
INSERT INTO BOLETA_PAGO (Num_boleta, Firma_trabajador, DNI, Num_inspeccion) VALUES
  ('BOL-202601-0001', 'Firmada', '42173460', 'INS-2026-01-001'),
  ('BOL-202601-0002', 'Firmada', '71523270', 'INS-2026-01-001'),
  ('BOL-202601-0003', 'Firmada', '75296053', 'INS-2026-01-001'),
  ('BOL-202601-0004', 'Firmada', '46830184', 'INS-2026-01-001'),
  ('BOL-202601-0005', 'Firmada', '43368451', 'INS-2026-01-001'),
  ('BOL-202601-0006', 'Firmada', '48299424', 'INS-2026-01-002'),
  ('BOL-202601-0007', 'Firmada', '75955639', 'INS-2026-01-002'),
  ('BOL-202601-0008', 'Firmada', '70180423', 'INS-2026-01-002'),
  ('BOL-202601-0009', 'Firmada', '70907576', 'INS-2026-01-002'),
  ('BOL-202601-0010', 'Firmada', '72315353', 'INS-2026-01-002'),
  ('BOL-202601-0011', 'Firmada', '71342606', 'INS-2026-01-002'),
  ('BOL-202601-0012', 'Firmada', '72015528', 'INS-2026-01-002'),
  ('BOL-202601-0013', 'Firmada', '40065537', 'INS-2026-01-002'),
  ('BOL-202601-0014', 'Firmada', '44441759', 'INS-2026-01-003'),
  ('BOL-202601-0015', 'Firmada', '74915035', 'INS-2026-01-003'),
  ('BOL-202601-0016', 'Firmada', '46476573', 'INS-2026-01-003'),
  ('BOL-202601-0017', 'Firmada', '71728206', 'INS-2026-01-003'),
  ('BOL-202601-0018', 'Firmada', '71675500', 'INS-2026-01-003'),
  ('BOL-202601-0019', 'Firmada', '71012734', 'INS-2026-01-003'),
  ('BOL-202601-0020', 'Firmada', '42982232', 'INS-2026-01-003'),
  ('BOL-202601-0021', 'Firmada', '72879685', 'INS-2026-01-003'),
  ('BOL-202601-0022', 'Firmada', '40916276', 'INS-2026-01-004'),
  ('BOL-202601-0023', 'Firmada', '73963527', 'INS-2026-01-004'),
  ('BOL-202601-0024', 'Firmada', '43892914', 'INS-2026-01-004'),
  ('BOL-202601-0025', 'Firmada', '75444200', 'INS-2026-01-004'),
  ('BOL-202601-0026', 'Firmada', '40644902', 'INS-2026-01-004'),
  ('BOL-202601-0027', 'Firmada', '45520843', 'INS-2026-01-004'),
  ('BOL-202601-0028', 'Firmada', '76965074', 'INS-2026-01-004'),
  ('BOL-202601-0029', 'Firmada', '41579947', 'INS-2026-01-004'),
  ('BOL-202601-0030', 'Firmada', '41406079', 'INS-2026-01-005'),
  ('BOL-202601-0031', 'Firmada', '72387158', 'INS-2026-01-005'),
  ('BOL-202601-0032', 'Firmada', '46695880', 'INS-2026-01-005'),
  ('BOL-202601-0033', 'Firmada', '74743120', 'INS-2026-01-005'),
  ('BOL-202601-0034', 'Firmada', '71383122', 'INS-2026-01-005'),
  ('BOL-202601-0035', 'Firmada', '73206828', 'INS-2026-01-006'),
  ('BOL-202601-0036', 'Firmada', '48126126', 'INS-2026-01-006'),
  ('BOL-202601-0037', 'Firmada', '73596879', 'INS-2026-01-006'),
  ('BOL-202601-0038', 'Firmada', '47979758', 'INS-2026-01-006'),
  ('BOL-202601-0039', 'Firmada', '47336743', 'INS-2026-01-006'),
  ('BOL-202601-0040', 'Firmada', '40865140', 'INS-2026-01-006'),
  ('BOL-202601-0041', 'Firmada', '43364705', 'INS-2026-01-006'),
  ('BOL-202601-0042', 'Firmada', '76581112', 'INS-2026-01-007'),
  ('BOL-202601-0043', 'Firmada', '47165365', 'INS-2026-01-007'),
  ('BOL-202601-0044', 'Firmada', '40131777', 'INS-2026-01-007'),
  ('BOL-202601-0045', 'Firmada', '71873068', 'INS-2026-01-007'),
  ('BOL-202601-0046', 'Firmada', '70079389', 'INS-2026-01-007'),
  ('BOL-202601-0047', 'Firmada', '45457987', 'INS-2026-01-007'),
  ('BOL-202601-0048', 'Firmada', '45731722', 'INS-2026-01-007'),
  ('BOL-202601-0049', 'Firmada', '45950756', 'INS-2026-01-008'),
  ('BOL-202601-0050', 'Firmada', '42219803', 'INS-2026-01-008'),
  ('BOL-202601-0051', 'Firmada', '72502438', 'INS-2026-01-008'),
  ('BOL-202601-0052', 'Firmada', '44423950', 'INS-2026-01-008'),
  ('BOL-202601-0053', 'Firmada', '45768741', 'INS-2026-01-008'),
  ('BOL-202601-0054', 'Firmada', '72493759', 'INS-2026-01-008'),
  ('BOL-202601-0055', 'Firmada', '74368538', 'INS-2026-01-008'),
  ('BOL-202601-0056', 'Firmada', '71815739', 'INS-2026-01-009'),
  ('BOL-202601-0057', 'Firmada', '43324473', 'INS-2026-01-009'),
  ('BOL-202601-0058', 'Firmada', '73928916', 'INS-2026-01-009'),
  ('BOL-202601-0059', 'Firmada', '46352975', 'INS-2026-01-009'),
  ('BOL-202601-0060', 'Firmada', '46230283', 'INS-2026-01-009'),
  ('BOL-202601-0061', 'Firmada', '76065004', 'INS-2026-01-010'),
  ('BOL-202601-0062', 'Firmada', '47728258', 'INS-2026-01-010'),
  ('BOL-202601-0063', 'Firmada', '76953642', 'INS-2026-01-010'),
  ('BOL-202601-0064', 'Firmada', '42276165', 'INS-2026-01-010'),
  ('BOL-202601-0065', 'Firmada', '76616396', 'INS-2026-01-010'),
  ('BOL-202601-0066', 'Firmada', '72116961', 'INS-2026-01-010'),
  ('BOL-202601-0067', 'Firmada', '73257171', 'INS-2026-01-011'),
  ('BOL-202601-0068', 'Firmada', '46500139', 'INS-2026-01-011'),
  ('BOL-202601-0069', 'Firmada', '73930805', 'INS-2026-01-011'),
  ('BOL-202601-0070', 'Firmada', '42812093', 'INS-2026-01-011'),
  ('BOL-202601-0071', 'Firmada', '73112728', 'INS-2026-01-011'),
  ('BOL-202601-0072', 'Firmada', '75751651', 'INS-2026-01-011'),
  ('BOL-202601-0073', 'Firmada', '47388246', 'INS-2026-01-011'),
  ('BOL-202602-0001', 'Firmada', '71815739', 'INS-2026-02-001'),
  ('BOL-202602-0002', 'Firmada', '43324473', 'INS-2026-02-001'),
  ('BOL-202602-0003', 'Firmada', '73928916', 'INS-2026-02-001'),
  ('BOL-202602-0004', 'Firmada', '46352975', 'INS-2026-02-001'),
  ('BOL-202602-0005', 'Firmada', '46230283', 'INS-2026-02-001'),
  ('BOL-202602-0006', 'Firmada', '76652718', 'INS-2026-02-002'),
  ('BOL-202602-0007', 'Firmada', '76006912', 'INS-2026-02-002'),
  ('BOL-202602-0008', 'Firmada', '71540558', 'INS-2026-02-002'),
  ('BOL-202602-0009', 'Firmada', '43751737', 'INS-2026-02-002'),
  ('BOL-202602-0010', 'Firmada', '44376048', 'INS-2026-02-002'),
  ('BOL-202602-0011', 'Firmada', '43761680', 'INS-2026-02-002'),
  ('BOL-202602-0012', 'Firmada', '42173460', 'INS-2026-02-003'),
  ('BOL-202602-0013', 'Firmada', '71523270', 'INS-2026-02-003'),
  ('BOL-202602-0014', 'Firmada', '75296053', 'INS-2026-02-003'),
  ('BOL-202602-0015', 'Firmada', '46830184', 'INS-2026-02-003'),
  ('BOL-202602-0016', 'Firmada', '43368451', 'INS-2026-02-003'),
  ('BOL-202602-0017', 'Firmada', '45950756', 'INS-2026-02-004'),
  ('BOL-202602-0018', 'Firmada', '42219803', 'INS-2026-02-004'),
  ('BOL-202602-0019', 'Firmada', '72502438', 'INS-2026-02-004'),
  ('BOL-202602-0020', 'Firmada', '44423950', 'INS-2026-02-004'),
  ('BOL-202602-0021', 'Firmada', '45768741', 'INS-2026-02-004'),
  ('BOL-202602-0022', 'Firmada', '72493759', 'INS-2026-02-004'),
  ('BOL-202602-0023', 'Firmada', '74368538', 'INS-2026-02-004'),
  ('BOL-202602-0024', 'Firmada', '48299424', 'INS-2026-02-005'),
  ('BOL-202602-0025', 'Firmada', '75955639', 'INS-2026-02-005'),
  ('BOL-202602-0026', 'Firmada', '70180423', 'INS-2026-02-005'),
  ('BOL-202602-0027', 'Firmada', '70907576', 'INS-2026-02-005');
INSERT INTO BOLETA_PAGO (Num_boleta, Firma_trabajador, DNI, Num_inspeccion) VALUES
  ('BOL-202602-0028', 'Firmada', '72315353', 'INS-2026-02-005'),
  ('BOL-202602-0029', 'Firmada', '71342606', 'INS-2026-02-005'),
  ('BOL-202602-0030', 'Firmada', '72015528', 'INS-2026-02-005'),
  ('BOL-202602-0031', 'Firmada', '40065537', 'INS-2026-02-005'),
  ('BOL-202602-0032', 'Firmada', '42163254', 'INS-2026-02-006'),
  ('BOL-202602-0033', 'Firmada', '40177862', 'INS-2026-02-006'),
  ('BOL-202602-0034', 'Firmada', '43708948', 'INS-2026-02-006'),
  ('BOL-202602-0035', 'Firmada', '46625414', 'INS-2026-02-006'),
  ('BOL-202602-0036', 'Firmada', '74813733', 'INS-2026-02-006'),
  ('BOL-202602-0037', 'Firmada', '45414231', 'INS-2026-02-006'),
  ('BOL-202602-0038', 'Firmada', '42240425', 'INS-2026-02-006'),
  ('BOL-202602-0039', 'Firmada', '71518007', 'INS-2026-02-006'),
  ('BOL-202602-0040', 'Firmada', '73257171', 'INS-2026-02-007'),
  ('BOL-202602-0041', 'Firmada', '46500139', 'INS-2026-02-007'),
  ('BOL-202602-0042', 'Firmada', '73930805', 'INS-2026-02-007'),
  ('BOL-202602-0043', 'Firmada', '42812093', 'INS-2026-02-007'),
  ('BOL-202602-0044', 'Firmada', '73112728', 'INS-2026-02-007'),
  ('BOL-202602-0045', 'Firmada', '75751651', 'INS-2026-02-007'),
  ('BOL-202602-0046', 'Firmada', '47388246', 'INS-2026-02-007'),
  ('BOL-202602-0047', 'Firmada', '41406079', 'INS-2026-02-008'),
  ('BOL-202602-0048', 'Firmada', '72387158', 'INS-2026-02-008'),
  ('BOL-202602-0049', 'Firmada', '46695880', 'INS-2026-02-008'),
  ('BOL-202602-0050', 'Firmada', '74743120', 'INS-2026-02-008'),
  ('BOL-202602-0051', 'Firmada', '71383122', 'INS-2026-02-008'),
  ('BOL-202602-0052', 'Firmada', '40916276', 'INS-2026-02-009'),
  ('BOL-202602-0053', 'Firmada', '73963527', 'INS-2026-02-009'),
  ('BOL-202602-0054', 'Firmada', '43892914', 'INS-2026-02-009'),
  ('BOL-202602-0055', 'Firmada', '75444200', 'INS-2026-02-009'),
  ('BOL-202602-0056', 'Firmada', '40644902', 'INS-2026-02-009'),
  ('BOL-202602-0057', 'Firmada', '45520843', 'INS-2026-02-009'),
  ('BOL-202602-0058', 'Firmada', '76965074', 'INS-2026-02-009'),
  ('BOL-202602-0059', 'Firmada', '41579947', 'INS-2026-02-009'),
  ('BOL-202602-0060', 'Firmada', '76581112', 'INS-2026-02-010'),
  ('BOL-202602-0061', 'Firmada', '47165365', 'INS-2026-02-010'),
  ('BOL-202602-0062', 'Firmada', '40131777', 'INS-2026-02-010'),
  ('BOL-202602-0063', 'Firmada', '71873068', 'INS-2026-02-010'),
  ('BOL-202602-0064', 'Firmada', '70079389', 'INS-2026-02-010'),
  ('BOL-202602-0065', 'Firmada', '45457987', 'INS-2026-02-010'),
  ('BOL-202602-0066', 'Firmada', '45731722', 'INS-2026-02-010'),
  ('BOL-202602-0067', 'Firmada', '44441759', 'INS-2026-02-011'),
  ('BOL-202602-0068', 'Firmada', '74915035', 'INS-2026-02-011'),
  ('BOL-202602-0069', 'Firmada', '46476573', 'INS-2026-02-011'),
  ('BOL-202602-0070', 'Firmada', '71728206', 'INS-2026-02-011'),
  ('BOL-202602-0071', 'Firmada', '71675500', 'INS-2026-02-011'),
  ('BOL-202602-0072', 'Firmada', '71012734', 'INS-2026-02-011'),
  ('BOL-202602-0073', 'Firmada', '42982232', 'INS-2026-02-011'),
  ('BOL-202602-0074', 'Firmada', '72879685', 'INS-2026-02-011'),
  ('BOL-202602-0075', 'Firmada', '76065004', 'INS-2026-02-012'),
  ('BOL-202602-0076', 'Firmada', '47728258', 'INS-2026-02-012'),
  ('BOL-202602-0077', 'Firmada', '76953642', 'INS-2026-02-012'),
  ('BOL-202602-0078', 'Firmada', '42276165', 'INS-2026-02-012'),
  ('BOL-202602-0079', 'Firmada', '76616396', 'INS-2026-02-012'),
  ('BOL-202602-0080', 'Firmada', '72116961', 'INS-2026-02-012'),
  ('BOL-202602-0081', 'Firmada', '73206828', 'INS-2026-02-013'),
  ('BOL-202602-0082', 'Firmada', '48126126', 'INS-2026-02-013'),
  ('BOL-202602-0083', 'Firmada', '73596879', 'INS-2026-02-013'),
  ('BOL-202602-0084', 'Firmada', '47979758', 'INS-2026-02-013'),
  ('BOL-202602-0085', 'Firmada', '47336743', 'INS-2026-02-013'),
  ('BOL-202602-0086', 'Firmada', '40865140', 'INS-2026-02-013'),
  ('BOL-202602-0087', 'Firmada', '43364705', 'INS-2026-02-013'),
  ('BOL-202602-0088', 'Firmada', '42163254', 'INS-2026-02-014'),
  ('BOL-202602-0089', 'Firmada', '40177862', 'INS-2026-02-014'),
  ('BOL-202602-0090', 'Firmada', '43708948', 'INS-2026-02-014'),
  ('BOL-202602-0091', 'Firmada', '46625414', 'INS-2026-02-014'),
  ('BOL-202602-0092', 'Firmada', '74813733', 'INS-2026-02-014'),
  ('BOL-202602-0093', 'Firmada', '45414231', 'INS-2026-02-014'),
  ('BOL-202602-0094', 'Firmada', '42240425', 'INS-2026-02-014'),
  ('BOL-202602-0095', 'Firmada', '71518007', 'INS-2026-02-014'),
  ('BOL-202603-0001', 'Firmada', '76581112', 'INS-2026-03-001'),
  ('BOL-202603-0002', 'Firmada', '47165365', 'INS-2026-03-001'),
  ('BOL-202603-0003', 'Firmada', '40131777', 'INS-2026-03-001'),
  ('BOL-202603-0004', 'Firmada', '71873068', 'INS-2026-03-001'),
  ('BOL-202603-0005', 'Firmada', '70079389', 'INS-2026-03-001'),
  ('BOL-202603-0006', 'Firmada', '45457987', 'INS-2026-03-001'),
  ('BOL-202603-0007', 'Firmada', '45731722', 'INS-2026-03-001'),
  ('BOL-202603-0008', 'Firmada', '44441759', 'INS-2026-03-002'),
  ('BOL-202603-0009', 'Firmada', '74915035', 'INS-2026-03-002'),
  ('BOL-202603-0010', 'Firmada', '46476573', 'INS-2026-03-002'),
  ('BOL-202603-0011', 'Firmada', '71728206', 'INS-2026-03-002'),
  ('BOL-202603-0012', 'Firmada', '71675500', 'INS-2026-03-002'),
  ('BOL-202603-0013', 'Firmada', '71012734', 'INS-2026-03-002'),
  ('BOL-202603-0014', 'Firmada', '42982232', 'INS-2026-03-002'),
  ('BOL-202603-0015', 'Firmada', '72879685', 'INS-2026-03-002'),
  ('BOL-202603-0016', 'Firmada', '42436230', 'INS-2026-03-003'),
  ('BOL-202603-0017', 'Firmada', '46083695', 'INS-2026-03-003'),
  ('BOL-202603-0018', 'Firmada', '72275217', 'INS-2026-03-003'),
  ('BOL-202603-0019', 'Firmada', '43510587', 'INS-2026-03-003'),
  ('BOL-202603-0020', 'Firmada', '71271679', 'INS-2026-03-003'),
  ('BOL-202603-0021', 'Firmada', '74338638', 'INS-2026-03-003'),
  ('BOL-202603-0022', 'Firmada', '41406079', 'INS-2026-03-004'),
  ('BOL-202603-0023', 'Firmada', '72387158', 'INS-2026-03-004'),
  ('BOL-202603-0024', 'Firmada', '46695880', 'INS-2026-03-004'),
  ('BOL-202603-0025', 'Firmada', '74743120', 'INS-2026-03-004'),
  ('BOL-202603-0026', 'Firmada', '71383122', 'INS-2026-03-004'),
  ('BOL-202603-0027', 'Firmada', '48299424', 'INS-2026-03-005'),
  ('BOL-202603-0028', 'Firmada', '75955639', 'INS-2026-03-005'),
  ('BOL-202603-0029', 'Firmada', '70180423', 'INS-2026-03-005'),
  ('BOL-202603-0030', 'Firmada', '70907576', 'INS-2026-03-005'),
  ('BOL-202603-0031', 'Firmada', '72315353', 'INS-2026-03-005'),
  ('BOL-202603-0032', 'Firmada', '71342606', 'INS-2026-03-005');
INSERT INTO BOLETA_PAGO (Num_boleta, Firma_trabajador, DNI, Num_inspeccion) VALUES
  ('BOL-202603-0033', 'Firmada', '72015528', 'INS-2026-03-005'),
  ('BOL-202603-0034', 'Firmada', '40065537', 'INS-2026-03-005'),
  ('BOL-202603-0035', 'Firmada', '40916276', 'INS-2026-03-006'),
  ('BOL-202603-0036', 'Firmada', '73963527', 'INS-2026-03-006'),
  ('BOL-202603-0037', 'Firmada', '43892914', 'INS-2026-03-006'),
  ('BOL-202603-0038', 'Firmada', '75444200', 'INS-2026-03-006'),
  ('BOL-202603-0039', 'Firmada', '40644902', 'INS-2026-03-006'),
  ('BOL-202603-0040', 'Firmada', '45520843', 'INS-2026-03-006'),
  ('BOL-202603-0041', 'Firmada', '76965074', 'INS-2026-03-006'),
  ('BOL-202603-0042', 'Firmada', '41579947', 'INS-2026-03-006'),
  ('BOL-202603-0043', 'Firmada', '45950756', 'INS-2026-03-007'),
  ('BOL-202603-0044', 'Firmada', '42219803', 'INS-2026-03-007'),
  ('BOL-202603-0045', 'Firmada', '72502438', 'INS-2026-03-007'),
  ('BOL-202603-0046', 'Firmada', '44423950', 'INS-2026-03-007'),
  ('BOL-202603-0047', 'Firmada', '45768741', 'INS-2026-03-007'),
  ('BOL-202603-0048', 'Firmada', '72493759', 'INS-2026-03-007'),
  ('BOL-202603-0049', 'Firmada', '74368538', 'INS-2026-03-007'),
  ('BOL-202603-0050', 'Firmada', '73257171', 'INS-2026-03-008'),
  ('BOL-202603-0051', 'Firmada', '46500139', 'INS-2026-03-008'),
  ('BOL-202603-0052', 'Firmada', '73930805', 'INS-2026-03-008'),
  ('BOL-202603-0053', 'Firmada', '42812093', 'INS-2026-03-008'),
  ('BOL-202603-0054', 'Firmada', '73112728', 'INS-2026-03-008'),
  ('BOL-202603-0055', 'Firmada', '75751651', 'INS-2026-03-008'),
  ('BOL-202603-0056', 'Firmada', '47388246', 'INS-2026-03-008'),
  ('BOL-202603-0057', 'Firmada', '42163254', 'INS-2026-03-009'),
  ('BOL-202603-0058', 'Firmada', '40177862', 'INS-2026-03-009'),
  ('BOL-202603-0059', 'Firmada', '43708948', 'INS-2026-03-009'),
  ('BOL-202603-0060', 'Firmada', '46625414', 'INS-2026-03-009'),
  ('BOL-202603-0061', 'Firmada', '74813733', 'INS-2026-03-009'),
  ('BOL-202603-0062', 'Firmada', '45414231', 'INS-2026-03-009'),
  ('BOL-202603-0063', 'Firmada', '42240425', 'INS-2026-03-009'),
  ('BOL-202603-0064', 'Firmada', '71518007', 'INS-2026-03-009'),
  ('BOL-202603-0065', 'Firmada', '76065004', 'INS-2026-03-010'),
  ('BOL-202603-0066', 'Firmada', '47728258', 'INS-2026-03-010'),
  ('BOL-202603-0067', 'Firmada', '76953642', 'INS-2026-03-010'),
  ('BOL-202603-0068', 'Firmada', '42276165', 'INS-2026-03-010'),
  ('BOL-202603-0069', 'Firmada', '76616396', 'INS-2026-03-010'),
  ('BOL-202603-0070', 'Firmada', '72116961', 'INS-2026-03-010'),
  ('BOL-202603-0071', 'Firmada', '42173460', 'INS-2026-03-011'),
  ('BOL-202603-0072', 'Firmada', '71523270', 'INS-2026-03-011'),
  ('BOL-202603-0073', 'Firmada', '75296053', 'INS-2026-03-011'),
  ('BOL-202603-0074', 'Firmada', '46830184', 'INS-2026-03-011'),
  ('BOL-202603-0075', 'Firmada', '43368451', 'INS-2026-03-011'),
  ('BOL-202603-0076', 'Firmada', '71815739', 'INS-2026-03-012'),
  ('BOL-202603-0077', 'Firmada', '43324473', 'INS-2026-03-012'),
  ('BOL-202603-0078', 'Firmada', '73928916', 'INS-2026-03-012'),
  ('BOL-202603-0079', 'Firmada', '46352975', 'INS-2026-03-012'),
  ('BOL-202603-0080', 'Firmada', '46230283', 'INS-2026-03-012'),
  ('BOL-202603-0081', 'Firmada', '76652718', 'INS-2026-03-013'),
  ('BOL-202603-0082', 'Firmada', '76006912', 'INS-2026-03-013'),
  ('BOL-202603-0083', 'Firmada', '71540558', 'INS-2026-03-013'),
  ('BOL-202603-0084', 'Firmada', '43751737', 'INS-2026-03-013'),
  ('BOL-202603-0085', 'Firmada', '44376048', 'INS-2026-03-013'),
  ('BOL-202603-0086', 'Firmada', '43761680', 'INS-2026-03-013'),
  ('BOL-202603-0087', 'Firmada', '73206828', 'INS-2026-03-014'),
  ('BOL-202603-0088', 'Firmada', '48126126', 'INS-2026-03-014'),
  ('BOL-202603-0089', 'Firmada', '73596879', 'INS-2026-03-014'),
  ('BOL-202603-0090', 'Firmada', '47979758', 'INS-2026-03-014'),
  ('BOL-202603-0091', 'Firmada', '47336743', 'INS-2026-03-014'),
  ('BOL-202603-0092', 'Firmada', '40865140', 'INS-2026-03-014'),
  ('BOL-202603-0093', 'Firmada', '43364705', 'INS-2026-03-014'),
  ('BOL-202603-0094', 'Firmada', '40916276', 'INS-2026-03-015'),
  ('BOL-202603-0095', 'Firmada', '73963527', 'INS-2026-03-015'),
  ('BOL-202603-0096', 'Firmada', '43892914', 'INS-2026-03-015'),
  ('BOL-202603-0097', 'Firmada', '75444200', 'INS-2026-03-015'),
  ('BOL-202603-0098', 'Firmada', '40644902', 'INS-2026-03-015'),
  ('BOL-202603-0099', 'Firmada', '45520843', 'INS-2026-03-015'),
  ('BOL-202603-0100', 'Firmada', '76965074', 'INS-2026-03-015'),
  ('BOL-202603-0101', 'Firmada', '41579947', 'INS-2026-03-015'),
  ('BOL-202604-0001', 'Firmada', '42436230', 'INS-2026-04-001'),
  ('BOL-202604-0002', 'Firmada', '46083695', 'INS-2026-04-001'),
  ('BOL-202604-0003', 'Firmada', '72275217', 'INS-2026-04-001'),
  ('BOL-202604-0004', 'Firmada', '43510587', 'INS-2026-04-001'),
  ('BOL-202604-0005', 'Firmada', '71271679', 'INS-2026-04-001'),
  ('BOL-202604-0006', 'Firmada', '74338638', 'INS-2026-04-001'),
  ('BOL-202604-0007', 'Firmada', '42163254', 'INS-2026-04-002'),
  ('BOL-202604-0008', 'Firmada', '40177862', 'INS-2026-04-002'),
  ('BOL-202604-0009', 'Firmada', '43708948', 'INS-2026-04-002'),
  ('BOL-202604-0010', 'Firmada', '46625414', 'INS-2026-04-002'),
  ('BOL-202604-0011', 'Firmada', '74813733', 'INS-2026-04-002'),
  ('BOL-202604-0012', 'Firmada', '45414231', 'INS-2026-04-002'),
  ('BOL-202604-0013', 'Firmada', '42240425', 'INS-2026-04-002'),
  ('BOL-202604-0014', 'Firmada', '71518007', 'INS-2026-04-002'),
  ('BOL-202604-0015', 'Firmada', '76065004', 'INS-2026-04-003'),
  ('BOL-202604-0016', 'Firmada', '47728258', 'INS-2026-04-003'),
  ('BOL-202604-0017', 'Firmada', '76953642', 'INS-2026-04-003'),
  ('BOL-202604-0018', 'Firmada', '42276165', 'INS-2026-04-003'),
  ('BOL-202604-0019', 'Firmada', '76616396', 'INS-2026-04-003'),
  ('BOL-202604-0020', 'Firmada', '72116961', 'INS-2026-04-003'),
  ('BOL-202604-0021', 'Firmada', '71815739', 'INS-2026-04-004'),
  ('BOL-202604-0022', 'Firmada', '43324473', 'INS-2026-04-004'),
  ('BOL-202604-0023', 'Firmada', '73928916', 'INS-2026-04-004'),
  ('BOL-202604-0024', 'Firmada', '46352975', 'INS-2026-04-004'),
  ('BOL-202604-0025', 'Firmada', '46230283', 'INS-2026-04-004'),
  ('BOL-202604-0026', 'Firmada', '40752228', 'INS-2026-04-005'),
  ('BOL-202604-0027', 'Firmada', '74002617', 'INS-2026-04-005'),
  ('BOL-202604-0028', 'Firmada', '40908215', 'INS-2026-04-005'),
  ('BOL-202604-0029', 'Firmada', '75587395', 'INS-2026-04-005'),
  ('BOL-202604-0030', 'Firmada', '71905242', 'INS-2026-04-005'),
  ('BOL-202604-0031', 'Firmada', '41406079', 'INS-2026-04-006');
INSERT INTO BOLETA_PAGO (Num_boleta, Firma_trabajador, DNI, Num_inspeccion) VALUES
  ('BOL-202604-0032', 'Firmada', '72387158', 'INS-2026-04-006'),
  ('BOL-202604-0033', 'Firmada', '46695880', 'INS-2026-04-006'),
  ('BOL-202604-0034', 'Firmada', '74743120', 'INS-2026-04-006'),
  ('BOL-202604-0035', 'Firmada', '71383122', 'INS-2026-04-006'),
  ('BOL-202604-0036', 'Firmada', '45950756', 'INS-2026-04-007'),
  ('BOL-202604-0037', 'Firmada', '42219803', 'INS-2026-04-007'),
  ('BOL-202604-0038', 'Firmada', '72502438', 'INS-2026-04-007'),
  ('BOL-202604-0039', 'Firmada', '44423950', 'INS-2026-04-007'),
  ('BOL-202604-0040', 'Firmada', '45768741', 'INS-2026-04-007'),
  ('BOL-202604-0041', 'Firmada', '72493759', 'INS-2026-04-007'),
  ('BOL-202604-0042', 'Firmada', '74368538', 'INS-2026-04-007'),
  ('BOL-202604-0043', 'Firmada', '42173460', 'INS-2026-04-008'),
  ('BOL-202604-0044', 'Firmada', '71523270', 'INS-2026-04-008'),
  ('BOL-202604-0045', 'Firmada', '75296053', 'INS-2026-04-008'),
  ('BOL-202604-0046', 'Firmada', '46830184', 'INS-2026-04-008'),
  ('BOL-202604-0047', 'Firmada', '43368451', 'INS-2026-04-008'),
  ('BOL-202604-0048', 'Firmada', '73257171', 'INS-2026-04-009'),
  ('BOL-202604-0049', 'Firmada', '46500139', 'INS-2026-04-009'),
  ('BOL-202604-0050', 'Firmada', '73930805', 'INS-2026-04-009'),
  ('BOL-202604-0051', 'Firmada', '42812093', 'INS-2026-04-009'),
  ('BOL-202604-0052', 'Firmada', '73112728', 'INS-2026-04-009'),
  ('BOL-202604-0053', 'Firmada', '75751651', 'INS-2026-04-009'),
  ('BOL-202604-0054', 'Firmada', '47388246', 'INS-2026-04-009'),
  ('BOL-202604-0055', 'Firmada', '76581112', 'INS-2026-04-010'),
  ('BOL-202604-0056', 'Firmada', '47165365', 'INS-2026-04-010'),
  ('BOL-202604-0057', 'Firmada', '40131777', 'INS-2026-04-010'),
  ('BOL-202604-0058', 'Firmada', '71873068', 'INS-2026-04-010'),
  ('BOL-202604-0059', 'Firmada', '70079389', 'INS-2026-04-010'),
  ('BOL-202604-0060', 'Firmada', '45457987', 'INS-2026-04-010'),
  ('BOL-202604-0061', 'Firmada', '45731722', 'INS-2026-04-010'),
  ('BOL-202604-0062', 'Firmada', '40916276', 'INS-2026-04-011'),
  ('BOL-202604-0063', 'Firmada', '73963527', 'INS-2026-04-011'),
  ('BOL-202604-0064', 'Firmada', '43892914', 'INS-2026-04-011'),
  ('BOL-202604-0065', 'Firmada', '75444200', 'INS-2026-04-011'),
  ('BOL-202604-0066', 'Firmada', '40644902', 'INS-2026-04-011'),
  ('BOL-202604-0067', 'Firmada', '45520843', 'INS-2026-04-011'),
  ('BOL-202604-0068', 'Firmada', '76965074', 'INS-2026-04-011'),
  ('BOL-202604-0069', 'Firmada', '41579947', 'INS-2026-04-011'),
  ('BOL-202604-0070', 'Firmada', '48299424', 'INS-2026-04-012'),
  ('BOL-202604-0071', 'Firmada', '75955639', 'INS-2026-04-012'),
  ('BOL-202604-0072', 'Firmada', '70180423', 'INS-2026-04-012'),
  ('BOL-202604-0073', 'Firmada', '70907576', 'INS-2026-04-012'),
  ('BOL-202604-0074', 'Firmada', '72315353', 'INS-2026-04-012'),
  ('BOL-202604-0075', 'Firmada', '71342606', 'INS-2026-04-012'),
  ('BOL-202604-0076', 'Firmada', '72015528', 'INS-2026-04-012'),
  ('BOL-202604-0077', 'Firmada', '40065537', 'INS-2026-04-012'),
  ('BOL-202604-0078', 'Firmada', '73206828', 'INS-2026-04-013'),
  ('BOL-202604-0079', 'Firmada', '48126126', 'INS-2026-04-013'),
  ('BOL-202604-0080', 'Firmada', '73596879', 'INS-2026-04-013'),
  ('BOL-202604-0081', 'Firmada', '47979758', 'INS-2026-04-013'),
  ('BOL-202604-0082', 'Firmada', '47336743', 'INS-2026-04-013'),
  ('BOL-202604-0083', 'Firmada', '40865140', 'INS-2026-04-013'),
  ('BOL-202604-0084', 'Firmada', '43364705', 'INS-2026-04-013'),
  ('BOL-202604-0085', 'Firmada', '44441759', 'INS-2026-04-014'),
  ('BOL-202604-0086', 'Firmada', '74915035', 'INS-2026-04-014'),
  ('BOL-202604-0087', 'Firmada', '46476573', 'INS-2026-04-014'),
  ('BOL-202604-0088', 'Firmada', '71728206', 'INS-2026-04-014'),
  ('BOL-202604-0089', 'Firmada', '71675500', 'INS-2026-04-014'),
  ('BOL-202604-0090', 'Firmada', '71012734', 'INS-2026-04-014'),
  ('BOL-202604-0091', 'Firmada', '42982232', 'INS-2026-04-014'),
  ('BOL-202604-0092', 'Firmada', '72879685', 'INS-2026-04-014'),
  ('BOL-202604-0093', 'Firmada', '76652718', 'INS-2026-04-015'),
  ('BOL-202604-0094', 'Firmada', '76006912', 'INS-2026-04-015'),
  ('BOL-202604-0095', 'Firmada', '71540558', 'INS-2026-04-015'),
  ('BOL-202604-0096', 'Firmada', '43751737', 'INS-2026-04-015'),
  ('BOL-202604-0097', 'Firmada', '44376048', 'INS-2026-04-015'),
  ('BOL-202604-0098', 'Firmada', '43761680', 'INS-2026-04-015'),
  ('BOL-202605-0001', 'Firmada', '42173460', 'INS-2026-05-001'),
  ('BOL-202605-0002', 'Firmada', '71523270', 'INS-2026-05-001'),
  ('BOL-202605-0003', 'Firmada', '75296053', 'INS-2026-05-001'),
  ('BOL-202605-0004', 'Firmada', '46830184', 'INS-2026-05-001'),
  ('BOL-202605-0005', 'Firmada', '43368451', 'INS-2026-05-001'),
  ('BOL-202605-0006', 'Firmada', '48299424', 'INS-2026-05-002'),
  ('BOL-202605-0007', 'Firmada', '75955639', 'INS-2026-05-002'),
  ('BOL-202605-0008', 'Firmada', '70180423', 'INS-2026-05-002'),
  ('BOL-202605-0009', 'Firmada', '70907576', 'INS-2026-05-002'),
  ('BOL-202605-0010', 'Firmada', '72315353', 'INS-2026-05-002'),
  ('BOL-202605-0011', 'Firmada', '71342606', 'INS-2026-05-002'),
  ('BOL-202605-0012', 'Firmada', '72015528', 'INS-2026-05-002'),
  ('BOL-202605-0013', 'Firmada', '40065537', 'INS-2026-05-002'),
  ('BOL-202605-0014', 'Firmada', '73206828', 'INS-2026-05-003'),
  ('BOL-202605-0015', 'Firmada', '48126126', 'INS-2026-05-003'),
  ('BOL-202605-0016', 'Firmada', '73596879', 'INS-2026-05-003'),
  ('BOL-202605-0017', 'Firmada', '47979758', 'INS-2026-05-003'),
  ('BOL-202605-0018', 'Firmada', '47336743', 'INS-2026-05-003'),
  ('BOL-202605-0019', 'Firmada', '40865140', 'INS-2026-05-003'),
  ('BOL-202605-0020', 'Firmada', '43364705', 'INS-2026-05-003'),
  ('BOL-202605-0021', 'Firmada', '42436230', 'INS-2026-05-004'),
  ('BOL-202605-0022', 'Firmada', '46083695', 'INS-2026-05-004'),
  ('BOL-202605-0023', 'Firmada', '72275217', 'INS-2026-05-004'),
  ('BOL-202605-0024', 'Firmada', '43510587', 'INS-2026-05-004'),
  ('BOL-202605-0025', 'Firmada', '71271679', 'INS-2026-05-004'),
  ('BOL-202605-0026', 'Firmada', '74338638', 'INS-2026-05-004'),
  ('BOL-202605-0027', 'Firmada', '41406079', 'INS-2026-05-005'),
  ('BOL-202605-0028', 'Firmada', '72387158', 'INS-2026-05-005'),
  ('BOL-202605-0029', 'Firmada', '46695880', 'INS-2026-05-005'),
  ('BOL-202605-0030', 'Firmada', '74743120', 'INS-2026-05-005'),
  ('BOL-202605-0031', 'Firmada', '71383122', 'INS-2026-05-005'),
  ('BOL-202605-0032', 'Firmada', '76652718', 'INS-2026-05-006'),
  ('BOL-202605-0033', 'Firmada', '76006912', 'INS-2026-05-006');
INSERT INTO BOLETA_PAGO (Num_boleta, Firma_trabajador, DNI, Num_inspeccion) VALUES
  ('BOL-202605-0034', 'Firmada', '71540558', 'INS-2026-05-006'),
  ('BOL-202605-0035', 'Firmada', '43751737', 'INS-2026-05-006'),
  ('BOL-202605-0036', 'Firmada', '44376048', 'INS-2026-05-006'),
  ('BOL-202605-0037', 'Firmada', '43761680', 'INS-2026-05-006'),
  ('BOL-202605-0038', 'Firmada', '45950756', 'INS-2026-05-007'),
  ('BOL-202605-0039', 'Firmada', '42219803', 'INS-2026-05-007'),
  ('BOL-202605-0040', 'Firmada', '72502438', 'INS-2026-05-007'),
  ('BOL-202605-0041', 'Firmada', '44423950', 'INS-2026-05-007'),
  ('BOL-202605-0042', 'Firmada', '45768741', 'INS-2026-05-007'),
  ('BOL-202605-0043', 'Firmada', '72493759', 'INS-2026-05-007'),
  ('BOL-202605-0044', 'Firmada', '74368538', 'INS-2026-05-007'),
  ('BOL-202605-0045', 'Firmada', '40916276', 'INS-2026-05-008'),
  ('BOL-202605-0046', 'Firmada', '73963527', 'INS-2026-05-008'),
  ('BOL-202605-0047', 'Firmada', '43892914', 'INS-2026-05-008'),
  ('BOL-202605-0048', 'Firmada', '75444200', 'INS-2026-05-008'),
  ('BOL-202605-0049', 'Firmada', '40644902', 'INS-2026-05-008'),
  ('BOL-202605-0050', 'Firmada', '45520843', 'INS-2026-05-008'),
  ('BOL-202605-0051', 'Firmada', '76965074', 'INS-2026-05-008'),
  ('BOL-202605-0052', 'Firmada', '41579947', 'INS-2026-05-008'),
  ('BOL-202605-0053', 'Firmada', '44441759', 'INS-2026-05-009'),
  ('BOL-202605-0054', 'Firmada', '74915035', 'INS-2026-05-009'),
  ('BOL-202605-0055', 'Firmada', '46476573', 'INS-2026-05-009'),
  ('BOL-202605-0056', 'Firmada', '71728206', 'INS-2026-05-009'),
  ('BOL-202605-0057', 'Firmada', '71675500', 'INS-2026-05-009'),
  ('BOL-202605-0058', 'Firmada', '71012734', 'INS-2026-05-009'),
  ('BOL-202605-0059', 'Firmada', '42982232', 'INS-2026-05-009'),
  ('BOL-202605-0060', 'Firmada', '72879685', 'INS-2026-05-009'),
  ('BOL-202605-0061', 'Firmada', '76065004', 'INS-2026-05-010'),
  ('BOL-202605-0062', 'Firmada', '47728258', 'INS-2026-05-010'),
  ('BOL-202605-0063', 'Firmada', '76953642', 'INS-2026-05-010'),
  ('BOL-202605-0064', 'Firmada', '42276165', 'INS-2026-05-010'),
  ('BOL-202605-0065', 'Firmada', '76616396', 'INS-2026-05-010'),
  ('BOL-202605-0066', 'Firmada', '72116961', 'INS-2026-05-010'),
  ('BOL-202605-0067', 'Firmada', '73899177', 'INS-2026-05-011'),
  ('BOL-202605-0068', 'Firmada', '46724988', 'INS-2026-05-011'),
  ('BOL-202605-0069', 'Firmada', '45023399', 'INS-2026-05-011'),
  ('BOL-202605-0070', 'Firmada', '74553619', 'INS-2026-05-011'),
  ('BOL-202605-0071', 'Firmada', '73363762', 'INS-2026-05-011'),
  ('BOL-202605-0072', 'Firmada', '71080618', 'INS-2026-05-011'),
  ('BOL-202605-0073', 'Firmada', '71815739', 'INS-2026-05-012'),
  ('BOL-202605-0074', 'Firmada', '43324473', 'INS-2026-05-012'),
  ('BOL-202605-0075', 'Firmada', '73928916', 'INS-2026-05-012'),
  ('BOL-202605-0076', 'Firmada', '46352975', 'INS-2026-05-012'),
  ('BOL-202605-0077', 'Firmada', '46230283', 'INS-2026-05-012'),
  ('BOL-202605-0078', 'Firmada', '40752228', 'INS-2026-05-013'),
  ('BOL-202605-0079', 'Firmada', '74002617', 'INS-2026-05-013'),
  ('BOL-202605-0080', 'Firmada', '40908215', 'INS-2026-05-013'),
  ('BOL-202605-0081', 'Firmada', '75587395', 'INS-2026-05-013'),
  ('BOL-202605-0082', 'Firmada', '71905242', 'INS-2026-05-013'),
  ('BOL-202605-0083', 'Firmada', '76581112', 'INS-2026-05-014'),
  ('BOL-202605-0084', 'Firmada', '47165365', 'INS-2026-05-014'),
  ('BOL-202605-0085', 'Firmada', '40131777', 'INS-2026-05-014'),
  ('BOL-202605-0086', 'Firmada', '71873068', 'INS-2026-05-014'),
  ('BOL-202605-0087', 'Firmada', '70079389', 'INS-2026-05-014'),
  ('BOL-202605-0088', 'Firmada', '45457987', 'INS-2026-05-014'),
  ('BOL-202605-0089', 'Firmada', '45731722', 'INS-2026-05-014'),
  ('BOL-202605-0090', 'Firmada', '41406079', 'INS-2026-05-015'),
  ('BOL-202605-0091', 'Firmada', '72387158', 'INS-2026-05-015'),
  ('BOL-202605-0092', 'Firmada', '46695880', 'INS-2026-05-015'),
  ('BOL-202605-0093', 'Firmada', '74743120', 'INS-2026-05-015'),
  ('BOL-202605-0094', 'Firmada', '71383122', 'INS-2026-05-015'),
  ('BOL-202605-0095', 'Firmada', '73257171', 'INS-2026-05-016'),
  ('BOL-202605-0096', 'Firmada', '46500139', 'INS-2026-05-016'),
  ('BOL-202605-0097', 'Firmada', '73930805', 'INS-2026-05-016'),
  ('BOL-202605-0098', 'Firmada', '42812093', 'INS-2026-05-016'),
  ('BOL-202605-0099', 'Firmada', '73112728', 'INS-2026-05-016'),
  ('BOL-202605-0100', 'Firmada', '75751651', 'INS-2026-05-016'),
  ('BOL-202605-0101', 'Firmada', '47388246', 'INS-2026-05-016'),
  ('BOL-202605-0102', 'Firmada', '42163254', 'INS-2026-05-017'),
  ('BOL-202605-0103', 'Firmada', '40177862', 'INS-2026-05-017'),
  ('BOL-202605-0104', 'Firmada', '43708948', 'INS-2026-05-017'),
  ('BOL-202605-0105', 'Firmada', '46625414', 'INS-2026-05-017'),
  ('BOL-202605-0106', 'Firmada', '74813733', 'INS-2026-05-017'),
  ('BOL-202605-0107', 'Firmada', '45414231', 'INS-2026-05-017'),
  ('BOL-202605-0108', 'Firmada', '42240425', 'INS-2026-05-017'),
  ('BOL-202605-0109', 'Firmada', '71518007', 'INS-2026-05-017'),
  ('BOL-202606-0001', 'Firmada', '42173460', 'INS-2026-06-001'),
  ('BOL-202606-0002', 'Firmada', '71523270', 'INS-2026-06-001'),
  ('BOL-202606-0003', 'Firmada', '75296053', 'INS-2026-06-001'),
  ('BOL-202606-0004', 'Firmada', '46830184', 'INS-2026-06-001'),
  ('BOL-202606-0005', 'Firmada', '43368451', 'INS-2026-06-001'),
  ('BOL-202606-0006', 'Firmada', '73206828', 'INS-2026-06-002'),
  ('BOL-202606-0007', 'Firmada', '48126126', 'INS-2026-06-002'),
  ('BOL-202606-0008', 'Firmada', '73596879', 'INS-2026-06-002'),
  ('BOL-202606-0009', 'Firmada', '47979758', 'INS-2026-06-002'),
  ('BOL-202606-0010', 'Firmada', '47336743', 'INS-2026-06-002'),
  ('BOL-202606-0011', 'Firmada', '40865140', 'INS-2026-06-002'),
  ('BOL-202606-0012', 'Firmada', '43364705', 'INS-2026-06-002'),
  ('BOL-202606-0013', 'Firmada', '48299424', 'INS-2026-06-003'),
  ('BOL-202606-0014', 'Firmada', '75955639', 'INS-2026-06-003'),
  ('BOL-202606-0015', 'Firmada', '70180423', 'INS-2026-06-003'),
  ('BOL-202606-0016', 'Firmada', '70907576', 'INS-2026-06-003'),
  ('BOL-202606-0017', 'Firmada', '72315353', 'INS-2026-06-003'),
  ('BOL-202606-0018', 'Firmada', '71342606', 'INS-2026-06-003'),
  ('BOL-202606-0019', 'Firmada', '72015528', 'INS-2026-06-003'),
  ('BOL-202606-0020', 'Firmada', '40065537', 'INS-2026-06-003'),
  ('BOL-202606-0021', 'Firmada', '73899177', 'INS-2026-06-004'),
  ('BOL-202606-0022', 'Firmada', '46724988', 'INS-2026-06-004'),
  ('BOL-202606-0023', 'Firmada', '45023399', 'INS-2026-06-004'),
  ('BOL-202606-0024', 'Firmada', '74553619', 'INS-2026-06-004');
INSERT INTO BOLETA_PAGO (Num_boleta, Firma_trabajador, DNI, Num_inspeccion) VALUES
  ('BOL-202606-0025', 'Firmada', '73363762', 'INS-2026-06-004'),
  ('BOL-202606-0026', 'Firmada', '71080618', 'INS-2026-06-004'),
  ('BOL-202606-0027', 'Firmada', '40916276', 'INS-2026-06-005'),
  ('BOL-202606-0028', 'Firmada', '73963527', 'INS-2026-06-005'),
  ('BOL-202606-0029', 'Firmada', '43892914', 'INS-2026-06-005'),
  ('BOL-202606-0030', 'Firmada', '75444200', 'INS-2026-06-005'),
  ('BOL-202606-0031', 'Firmada', '40644902', 'INS-2026-06-005'),
  ('BOL-202606-0032', 'Firmada', '45520843', 'INS-2026-06-005'),
  ('BOL-202606-0033', 'Firmada', '76965074', 'INS-2026-06-005'),
  ('BOL-202606-0034', 'Firmada', '41579947', 'INS-2026-06-005'),
  ('BOL-202606-0035', 'Firmada', '73257171', 'INS-2026-06-006'),
  ('BOL-202606-0036', 'Firmada', '46500139', 'INS-2026-06-006'),
  ('BOL-202606-0037', 'Firmada', '73930805', 'INS-2026-06-006'),
  ('BOL-202606-0038', 'Firmada', '42812093', 'INS-2026-06-006'),
  ('BOL-202606-0039', 'Firmada', '73112728', 'INS-2026-06-006'),
  ('BOL-202606-0040', 'Firmada', '75751651', 'INS-2026-06-006'),
  ('BOL-202606-0041', 'Firmada', '47388246', 'INS-2026-06-006'),
  ('BOL-202606-0042', 'Firmada', '76581112', 'INS-2026-06-007'),
  ('BOL-202606-0043', 'Firmada', '47165365', 'INS-2026-06-007'),
  ('BOL-202606-0044', 'Firmada', '40131777', 'INS-2026-06-007'),
  ('BOL-202606-0045', 'Firmada', '71873068', 'INS-2026-06-007'),
  ('BOL-202606-0046', 'Firmada', '70079389', 'INS-2026-06-007'),
  ('BOL-202606-0047', 'Firmada', '45457987', 'INS-2026-06-007'),
  ('BOL-202606-0048', 'Firmada', '45731722', 'INS-2026-06-007'),
  ('BOL-202606-0049', 'Firmada', '42163254', 'INS-2026-06-008'),
  ('BOL-202606-0050', 'Firmada', '40177862', 'INS-2026-06-008'),
  ('BOL-202606-0051', 'Firmada', '43708948', 'INS-2026-06-008'),
  ('BOL-202606-0052', 'Firmada', '46625414', 'INS-2026-06-008'),
  ('BOL-202606-0053', 'Firmada', '74813733', 'INS-2026-06-008'),
  ('BOL-202606-0054', 'Firmada', '45414231', 'INS-2026-06-008'),
  ('BOL-202606-0055', 'Firmada', '42240425', 'INS-2026-06-008'),
  ('BOL-202606-0056', 'Firmada', '71518007', 'INS-2026-06-008'),
  ('BOL-202606-0057', 'Firmada', '71815739', 'INS-2026-06-009'),
  ('BOL-202606-0058', 'Firmada', '43324473', 'INS-2026-06-009'),
  ('BOL-202606-0059', 'Firmada', '73928916', 'INS-2026-06-009'),
  ('BOL-202606-0060', 'Firmada', '46352975', 'INS-2026-06-009'),
  ('BOL-202606-0061', 'Firmada', '46230283', 'INS-2026-06-009'),
  ('BOL-202606-0062', 'Firmada', '41406079', 'INS-2026-06-010'),
  ('BOL-202606-0063', 'Firmada', '72387158', 'INS-2026-06-010'),
  ('BOL-202606-0064', 'Firmada', '46695880', 'INS-2026-06-010'),
  ('BOL-202606-0065', 'Firmada', '74743120', 'INS-2026-06-010'),
  ('BOL-202606-0066', 'Firmada', '71383122', 'INS-2026-06-010'),
  ('BOL-202606-0067', 'Firmada', '40752228', 'INS-2026-06-011'),
  ('BOL-202606-0068', 'Firmada', '74002617', 'INS-2026-06-011'),
  ('BOL-202606-0069', 'Firmada', '40908215', 'INS-2026-06-011'),
  ('BOL-202606-0070', 'Firmada', '75587395', 'INS-2026-06-011'),
  ('BOL-202606-0071', 'Firmada', '71905242', 'INS-2026-06-011'),
  ('BOL-202606-0072', 'Firmada', '76065004', 'INS-2026-06-012'),
  ('BOL-202606-0073', 'Firmada', '47728258', 'INS-2026-06-012'),
  ('BOL-202606-0074', 'Firmada', '76953642', 'INS-2026-06-012'),
  ('BOL-202606-0075', 'Firmada', '42276165', 'INS-2026-06-012'),
  ('BOL-202606-0076', 'Firmada', '76616396', 'INS-2026-06-012'),
  ('BOL-202606-0077', 'Firmada', '72116961', 'INS-2026-06-012'),
  ('BOL-202606-0078', 'Firmada', '45950756', 'INS-2026-06-013'),
  ('BOL-202606-0079', 'Firmada', '42219803', 'INS-2026-06-013'),
  ('BOL-202606-0080', 'Firmada', '72502438', 'INS-2026-06-013'),
  ('BOL-202606-0081', 'Firmada', '44423950', 'INS-2026-06-013'),
  ('BOL-202606-0082', 'Firmada', '45768741', 'INS-2026-06-013'),
  ('BOL-202606-0083', 'Firmada', '72493759', 'INS-2026-06-013'),
  ('BOL-202606-0084', 'Firmada', '74368538', 'INS-2026-06-013'),
  ('BOL-202606-0085', 'Firmada', '44441759', 'INS-2026-06-014'),
  ('BOL-202606-0086', 'Firmada', '74915035', 'INS-2026-06-014'),
  ('BOL-202606-0087', 'Firmada', '46476573', 'INS-2026-06-014'),
  ('BOL-202606-0088', 'Firmada', '71728206', 'INS-2026-06-014'),
  ('BOL-202606-0089', 'Firmada', '71675500', 'INS-2026-06-014'),
  ('BOL-202606-0090', 'Firmada', '71012734', 'INS-2026-06-014'),
  ('BOL-202606-0091', 'Firmada', '42982232', 'INS-2026-06-014'),
  ('BOL-202606-0092', 'Firmada', '72879685', 'INS-2026-06-014'),
  ('BOL-202606-0093', 'Firmada', '42436230', 'INS-2026-06-015'),
  ('BOL-202606-0094', 'Firmada', '46083695', 'INS-2026-06-015'),
  ('BOL-202606-0095', 'Firmada', '72275217', 'INS-2026-06-015'),
  ('BOL-202606-0096', 'Firmada', '43510587', 'INS-2026-06-015'),
  ('BOL-202606-0097', 'Firmada', '71271679', 'INS-2026-06-015'),
  ('BOL-202606-0098', 'Firmada', '74338638', 'INS-2026-06-015'),
  ('BOL-202606-0099', 'Firmada', '76652718', 'INS-2026-06-016'),
  ('BOL-202606-0100', 'Firmada', '76006912', 'INS-2026-06-016'),
  ('BOL-202606-0101', 'Firmada', '71540558', 'INS-2026-06-016'),
  ('BOL-202606-0102', 'Firmada', '43751737', 'INS-2026-06-016'),
  ('BOL-202606-0103', 'Firmada', '44376048', 'INS-2026-06-016'),
  ('BOL-202606-0104', 'Firmada', '43761680', 'INS-2026-06-016'),
  ('BOL-202607-0001', 'Firmada', '40916276', 'INS-2026-07-001'),
  ('BOL-202607-0002', 'Firmada', '73963527', 'INS-2026-07-001'),
  ('BOL-202607-0003', 'Firmada', '43892914', 'INS-2026-07-001'),
  ('BOL-202607-0004', 'Firmada', '75444200', 'INS-2026-07-001'),
  ('BOL-202607-0005', 'Firmada', '40644902', 'INS-2026-07-001'),
  ('BOL-202607-0006', 'Firmada', '45520843', 'INS-2026-07-001'),
  ('BOL-202607-0007', 'Firmada', '76965074', 'INS-2026-07-001'),
  ('BOL-202607-0008', 'Firmada', '41579947', 'INS-2026-07-001'),
  ('BOL-202607-0009', 'Firmada', '73899177', 'INS-2026-07-002'),
  ('BOL-202607-0010', 'Firmada', '46724988', 'INS-2026-07-002'),
  ('BOL-202607-0011', 'Firmada', '45023399', 'INS-2026-07-002'),
  ('BOL-202607-0012', 'Firmada', '74553619', 'INS-2026-07-002'),
  ('BOL-202607-0013', 'Firmada', '73363762', 'INS-2026-07-002'),
  ('BOL-202607-0014', 'Firmada', '71080618', 'INS-2026-07-002'),
  ('BOL-202607-0015', 'Firmada', '42173460', 'INS-2026-07-003'),
  ('BOL-202607-0016', 'Firmada', '71523270', 'INS-2026-07-003'),
  ('BOL-202607-0017', 'Firmada', '75296053', 'INS-2026-07-003'),
  ('BOL-202607-0018', 'Firmada', '46830184', 'INS-2026-07-003'),
  ('BOL-202607-0019', 'Firmada', '43368451', 'INS-2026-07-003'),
  ('BOL-202607-0020', 'Firmada', '42163254', 'INS-2026-07-004');
INSERT INTO BOLETA_PAGO (Num_boleta, Firma_trabajador, DNI, Num_inspeccion) VALUES
  ('BOL-202607-0021', 'Firmada', '40177862', 'INS-2026-07-004'),
  ('BOL-202607-0022', 'Firmada', '43708948', 'INS-2026-07-004'),
  ('BOL-202607-0023', 'Firmada', '46625414', 'INS-2026-07-004'),
  ('BOL-202607-0024', 'Firmada', '74813733', 'INS-2026-07-004'),
  ('BOL-202607-0025', 'Firmada', '45414231', 'INS-2026-07-004'),
  ('BOL-202607-0026', 'Firmada', '42240425', 'INS-2026-07-004'),
  ('BOL-202607-0027', 'Firmada', '71518007', 'INS-2026-07-004'),
  ('BOL-202607-0028', 'Firmada', '44441759', 'INS-2026-07-005'),
  ('BOL-202607-0029', 'Firmada', '74915035', 'INS-2026-07-005'),
  ('BOL-202607-0030', 'Firmada', '46476573', 'INS-2026-07-005'),
  ('BOL-202607-0031', 'Firmada', '71728206', 'INS-2026-07-005'),
  ('BOL-202607-0032', 'Firmada', '71675500', 'INS-2026-07-005'),
  ('BOL-202607-0033', 'Firmada', '71012734', 'INS-2026-07-005'),
  ('BOL-202607-0034', 'Firmada', '42982232', 'INS-2026-07-005'),
  ('BOL-202607-0035', 'Firmada', '72879685', 'INS-2026-07-005'),
  ('BOL-202607-0036', 'Firmada', '76065004', 'INS-2026-07-006'),
  ('BOL-202607-0037', 'Firmada', '47728258', 'INS-2026-07-006'),
  ('BOL-202607-0038', 'Firmada', '76953642', 'INS-2026-07-006'),
  ('BOL-202607-0039', 'Firmada', '42276165', 'INS-2026-07-006'),
  ('BOL-202607-0040', 'Firmada', '76616396', 'INS-2026-07-006'),
  ('BOL-202607-0041', 'Firmada', '72116961', 'INS-2026-07-006'),
  ('BOL-202607-0042', 'No firmada', '48299424', 'INS-2026-07-007'),
  ('BOL-202607-0043', 'No firmada', '75955639', 'INS-2026-07-007'),
  ('BOL-202607-0044', 'Firmada', '70180423', 'INS-2026-07-007'),
  ('BOL-202607-0045', 'Firmada', '70907576', 'INS-2026-07-007'),
  ('BOL-202607-0046', 'Firmada', '72315353', 'INS-2026-07-007'),
  ('BOL-202607-0047', 'Firmada', '71342606', 'INS-2026-07-007'),
  ('BOL-202607-0048', 'Firmada', '72015528', 'INS-2026-07-007'),
  ('BOL-202607-0049', 'Firmada', '40065537', 'INS-2026-07-007'),
  ('BOL-202607-0050', 'Firmada', '73206828', 'INS-2026-07-008'),
  ('BOL-202607-0051', 'Firmada', '48126126', 'INS-2026-07-008'),
  ('BOL-202607-0052', 'Firmada', '73596879', 'INS-2026-07-008'),
  ('BOL-202607-0053', 'Firmada', '47979758', 'INS-2026-07-008'),
  ('BOL-202607-0054', 'Firmada', '47336743', 'INS-2026-07-008'),
  ('BOL-202607-0055', 'Firmada', '40865140', 'INS-2026-07-008'),
  ('BOL-202607-0056', 'Firmada', '43364705', 'INS-2026-07-008'),
  ('BOL-202607-0057', 'Firmada', '73257171', 'INS-2026-07-009'),
  ('BOL-202607-0058', 'Firmada', '46500139', 'INS-2026-07-009'),
  ('BOL-202607-0059', 'Firmada', '73930805', 'INS-2026-07-009'),
  ('BOL-202607-0060', 'Firmada', '42812093', 'INS-2026-07-009'),
  ('BOL-202607-0061', 'Firmada', '73112728', 'INS-2026-07-009'),
  ('BOL-202607-0062', 'Firmada', '75751651', 'INS-2026-07-009'),
  ('BOL-202607-0063', 'Firmada', '47388246', 'INS-2026-07-009'),
  ('BOL-202607-0064', 'Firmada', '41406079', 'INS-2026-07-011'),
  ('BOL-202607-0065', 'Firmada', '72387158', 'INS-2026-07-011'),
  ('BOL-202607-0066', 'Firmada', '46695880', 'INS-2026-07-011'),
  ('BOL-202607-0067', 'Firmada', '74743120', 'INS-2026-07-011'),
  ('BOL-202607-0068', 'Firmada', '71383122', 'INS-2026-07-011'),
  ('BOL-202607-0069', 'Firmada', '45950756', 'INS-2026-07-012'),
  ('BOL-202607-0070', 'Firmada', '42219803', 'INS-2026-07-012'),
  ('BOL-202607-0071', 'Firmada', '72502438', 'INS-2026-07-012'),
  ('BOL-202607-0072', 'Firmada', '44423950', 'INS-2026-07-012'),
  ('BOL-202607-0073', 'Firmada', '45768741', 'INS-2026-07-012'),
  ('BOL-202607-0074', 'Firmada', '72493759', 'INS-2026-07-012'),
  ('BOL-202607-0075', 'Firmada', '74368538', 'INS-2026-07-012'),
  ('BOL-202607-0076', 'Firmada', '71815739', 'INS-2026-07-013'),
  ('BOL-202607-0077', 'Firmada', '43324473', 'INS-2026-07-013'),
  ('BOL-202607-0078', 'Firmada', '73928916', 'INS-2026-07-013'),
  ('BOL-202607-0079', 'Firmada', '46352975', 'INS-2026-07-013'),
  ('BOL-202607-0080', 'Firmada', '46230283', 'INS-2026-07-013'),
  ('BOL-202607-0081', 'Firmada', '76581112', 'INS-2026-07-014'),
  ('BOL-202607-0082', 'Firmada', '47165365', 'INS-2026-07-014'),
  ('BOL-202607-0083', 'Firmada', '40131777', 'INS-2026-07-014'),
  ('BOL-202607-0084', 'Firmada', '71873068', 'INS-2026-07-014'),
  ('BOL-202607-0085', 'Firmada', '70079389', 'INS-2026-07-014'),
  ('BOL-202607-0086', 'Firmada', '45457987', 'INS-2026-07-014'),
  ('BOL-202607-0087', 'Firmada', '45731722', 'INS-2026-07-014'),
  ('BOL-202607-0088', 'Firmada', '40752228', 'INS-2026-07-015'),
  ('BOL-202607-0089', 'Firmada', '74002617', 'INS-2026-07-015'),
  ('BOL-202607-0090', 'Firmada', '40908215', 'INS-2026-07-015'),
  ('BOL-202607-0091', 'Firmada', '75587395', 'INS-2026-07-015'),
  ('BOL-202607-0092', 'Firmada', '71905242', 'INS-2026-07-015'),
  ('BOL-202607-0093', 'Firmada', '76652718', 'INS-2026-07-016'),
  ('BOL-202607-0094', 'Firmada', '76006912', 'INS-2026-07-016'),
  ('BOL-202607-0095', 'Firmada', '71540558', 'INS-2026-07-016'),
  ('BOL-202607-0096', 'Firmada', '43751737', 'INS-2026-07-016'),
  ('BOL-202607-0097', 'Firmada', '44376048', 'INS-2026-07-016'),
  ('BOL-202607-0098', 'Firmada', '43761680', 'INS-2026-07-016'),
  ('BOL-202608-0001', 'Firmada', '41406079', 'INS-2026-08-001'),
  ('BOL-202608-0002', 'Firmada', '72387158', 'INS-2026-08-001'),
  ('BOL-202608-0003', 'Firmada', '46695880', 'INS-2026-08-001'),
  ('BOL-202608-0004', 'Firmada', '74743120', 'INS-2026-08-001'),
  ('BOL-202608-0005', 'Firmada', '71383122', 'INS-2026-08-001'),
  ('BOL-202608-0006', 'Firmada', '76652718', 'INS-2026-08-002'),
  ('BOL-202608-0007', 'Firmada', '76006912', 'INS-2026-08-002'),
  ('BOL-202608-0008', 'Firmada', '71540558', 'INS-2026-08-002'),
  ('BOL-202608-0009', 'Firmada', '43751737', 'INS-2026-08-002'),
  ('BOL-202608-0010', 'Firmada', '44376048', 'INS-2026-08-002'),
  ('BOL-202608-0011', 'Firmada', '43761680', 'INS-2026-08-002'),
  ('BOL-202608-0012', 'Firmada', '76065004', 'INS-2026-08-003'),
  ('BOL-202608-0013', 'Firmada', '47728258', 'INS-2026-08-003'),
  ('BOL-202608-0014', 'Firmada', '76953642', 'INS-2026-08-003'),
  ('BOL-202608-0015', 'Firmada', '42276165', 'INS-2026-08-003'),
  ('BOL-202608-0016', 'Firmada', '76616396', 'INS-2026-08-003'),
  ('BOL-202608-0017', 'Firmada', '72116961', 'INS-2026-08-003'),
  ('BOL-202608-0018', 'Firmada', '48299424', 'INS-2026-08-004'),
  ('BOL-202608-0019', 'Firmada', '75955639', 'INS-2026-08-004'),
  ('BOL-202608-0020', 'Firmada', '70180423', 'INS-2026-08-004'),
  ('BOL-202608-0021', 'Firmada', '70907576', 'INS-2026-08-004'),
  ('BOL-202608-0022', 'Firmada', '72315353', 'INS-2026-08-004');
INSERT INTO BOLETA_PAGO (Num_boleta, Firma_trabajador, DNI, Num_inspeccion) VALUES
  ('BOL-202608-0023', 'Firmada', '71342606', 'INS-2026-08-004'),
  ('BOL-202608-0024', 'Firmada', '72015528', 'INS-2026-08-004'),
  ('BOL-202608-0025', 'Firmada', '40065537', 'INS-2026-08-004'),
  ('BOL-202608-0026', 'Firmada', '71815739', 'INS-2026-08-005'),
  ('BOL-202608-0027', 'Firmada', '43324473', 'INS-2026-08-005'),
  ('BOL-202608-0028', 'Firmada', '73928916', 'INS-2026-08-005'),
  ('BOL-202608-0029', 'Firmada', '46352975', 'INS-2026-08-005'),
  ('BOL-202608-0030', 'Firmada', '46230283', 'INS-2026-08-005'),
  ('BOL-202608-0031', 'Firmada', '45950756', 'INS-2026-08-006'),
  ('BOL-202608-0032', 'Firmada', '42219803', 'INS-2026-08-006'),
  ('BOL-202608-0033', 'Firmada', '72502438', 'INS-2026-08-006'),
  ('BOL-202608-0034', 'Firmada', '44423950', 'INS-2026-08-006'),
  ('BOL-202608-0035', 'Firmada', '45768741', 'INS-2026-08-006'),
  ('BOL-202608-0036', 'Firmada', '72493759', 'INS-2026-08-006'),
  ('BOL-202608-0037', 'Firmada', '74368538', 'INS-2026-08-006'),
  ('BOL-202608-0038', 'Firmada', '42173460', 'INS-2026-08-007'),
  ('BOL-202608-0039', 'Firmada', '71523270', 'INS-2026-08-007'),
  ('BOL-202608-0040', 'Firmada', '75296053', 'INS-2026-08-007'),
  ('BOL-202608-0041', 'Firmada', '46830184', 'INS-2026-08-007'),
  ('BOL-202608-0042', 'Firmada', '43368451', 'INS-2026-08-007'),
  ('BOL-202608-0043', 'Firmada', '42163254', 'INS-2026-08-008'),
  ('BOL-202608-0044', 'Firmada', '40177862', 'INS-2026-08-008'),
  ('BOL-202608-0045', 'Firmada', '43708948', 'INS-2026-08-008'),
  ('BOL-202608-0046', 'Firmada', '46625414', 'INS-2026-08-008'),
  ('BOL-202608-0047', 'Firmada', '74813733', 'INS-2026-08-008'),
  ('BOL-202608-0048', 'Firmada', '45414231', 'INS-2026-08-008'),
  ('BOL-202608-0049', 'Firmada', '42240425', 'INS-2026-08-008'),
  ('BOL-202608-0050', 'Firmada', '71518007', 'INS-2026-08-008'),
  ('BOL-202608-0051', 'Firmada', '40916276', 'INS-2026-08-009'),
  ('BOL-202608-0052', 'Firmada', '73963527', 'INS-2026-08-009'),
  ('BOL-202608-0053', 'Firmada', '43892914', 'INS-2026-08-009'),
  ('BOL-202608-0054', 'Firmada', '75444200', 'INS-2026-08-009'),
  ('BOL-202608-0055', 'Firmada', '40644902', 'INS-2026-08-009'),
  ('BOL-202608-0056', 'Firmada', '45520843', 'INS-2026-08-009'),
  ('BOL-202608-0057', 'Firmada', '76965074', 'INS-2026-08-009'),
  ('BOL-202608-0058', 'Firmada', '41579947', 'INS-2026-08-009'),
  ('BOL-202608-0059', 'Firmada', '73257171', 'INS-2026-08-010'),
  ('BOL-202608-0060', 'Firmada', '46500139', 'INS-2026-08-010'),
  ('BOL-202608-0061', 'Firmada', '73930805', 'INS-2026-08-010'),
  ('BOL-202608-0062', 'Firmada', '42812093', 'INS-2026-08-010'),
  ('BOL-202608-0063', 'Firmada', '73112728', 'INS-2026-08-010'),
  ('BOL-202608-0064', 'Firmada', '75751651', 'INS-2026-08-010'),
  ('BOL-202608-0065', 'Firmada', '47388246', 'INS-2026-08-010'),
  ('BOL-202608-0066', 'Firmada', '73899177', 'INS-2026-08-011'),
  ('BOL-202608-0067', 'Firmada', '46724988', 'INS-2026-08-011'),
  ('BOL-202608-0068', 'Firmada', '45023399', 'INS-2026-08-011'),
  ('BOL-202608-0069', 'Firmada', '74553619', 'INS-2026-08-011'),
  ('BOL-202608-0070', 'Firmada', '73363762', 'INS-2026-08-011'),
  ('BOL-202608-0071', 'Firmada', '71080618', 'INS-2026-08-011'),
  ('BOL-202608-0072', 'Firmada', '44441759', 'INS-2026-08-012'),
  ('BOL-202608-0073', 'Firmada', '74915035', 'INS-2026-08-012'),
  ('BOL-202608-0074', 'Firmada', '46476573', 'INS-2026-08-012'),
  ('BOL-202608-0075', 'Firmada', '71728206', 'INS-2026-08-012'),
  ('BOL-202608-0076', 'Firmada', '71675500', 'INS-2026-08-012'),
  ('BOL-202608-0077', 'Firmada', '71012734', 'INS-2026-08-012'),
  ('BOL-202608-0078', 'Firmada', '42982232', 'INS-2026-08-012'),
  ('BOL-202608-0079', 'Firmada', '72879685', 'INS-2026-08-012'),
  ('BOL-202608-0080', 'Firmada', '42436230', 'INS-2026-08-013'),
  ('BOL-202608-0081', 'Firmada', '46083695', 'INS-2026-08-013'),
  ('BOL-202608-0082', 'Firmada', '72275217', 'INS-2026-08-013'),
  ('BOL-202608-0083', 'Firmada', '43510587', 'INS-2026-08-013'),
  ('BOL-202608-0084', 'Firmada', '71271679', 'INS-2026-08-013'),
  ('BOL-202608-0085', 'Firmada', '74338638', 'INS-2026-08-013'),
  ('BOL-202608-0086', 'Firmada', '73206828', 'INS-2026-08-014'),
  ('BOL-202608-0087', 'Firmada', '48126126', 'INS-2026-08-014'),
  ('BOL-202608-0088', 'Firmada', '73596879', 'INS-2026-08-014'),
  ('BOL-202608-0089', 'Firmada', '47979758', 'INS-2026-08-014'),
  ('BOL-202608-0090', 'Firmada', '47336743', 'INS-2026-08-014'),
  ('BOL-202608-0091', 'Firmada', '40865140', 'INS-2026-08-014'),
  ('BOL-202608-0092', 'Firmada', '43364705', 'INS-2026-08-014'),
  ('BOL-202608-0093', 'Firmada', '76581112', 'INS-2026-08-015'),
  ('BOL-202608-0094', 'Firmada', '47165365', 'INS-2026-08-015'),
  ('BOL-202608-0095', 'Firmada', '40131777', 'INS-2026-08-015'),
  ('BOL-202608-0096', 'Firmada', '71873068', 'INS-2026-08-015'),
  ('BOL-202608-0097', 'Firmada', '70079389', 'INS-2026-08-015'),
  ('BOL-202608-0098', 'Firmada', '45457987', 'INS-2026-08-015'),
  ('BOL-202608-0099', 'Firmada', '45731722', 'INS-2026-08-015'),
  ('BOL-202608-0100', 'Firmada', '40752228', 'INS-2026-08-016'),
  ('BOL-202608-0101', 'Firmada', '74002617', 'INS-2026-08-016'),
  ('BOL-202608-0102', 'Firmada', '40908215', 'INS-2026-08-016'),
  ('BOL-202608-0103', 'Firmada', '75587395', 'INS-2026-08-016'),
  ('BOL-202608-0104', 'Firmada', '71905242', 'INS-2026-08-016'),
  ('BOL-202609-0001', 'Firmada', '76065004', 'INS-2026-09-001'),
  ('BOL-202609-0002', 'Firmada', '47728258', 'INS-2026-09-001'),
  ('BOL-202609-0003', 'Firmada', '76953642', 'INS-2026-09-001'),
  ('BOL-202609-0004', 'Firmada', '42276165', 'INS-2026-09-001'),
  ('BOL-202609-0005', 'Firmada', '76616396', 'INS-2026-09-001'),
  ('BOL-202609-0006', 'Firmada', '72116961', 'INS-2026-09-001'),
  ('BOL-202609-0007', 'Firmada', '42173460', 'INS-2026-09-002'),
  ('BOL-202609-0008', 'Firmada', '71523270', 'INS-2026-09-002'),
  ('BOL-202609-0009', 'Firmada', '75296053', 'INS-2026-09-002'),
  ('BOL-202609-0010', 'Firmada', '46830184', 'INS-2026-09-002'),
  ('BOL-202609-0011', 'Firmada', '43368451', 'INS-2026-09-002'),
  ('BOL-202609-0012', 'Firmada', '42436230', 'INS-2026-09-003'),
  ('BOL-202609-0013', 'Firmada', '46083695', 'INS-2026-09-003'),
  ('BOL-202609-0014', 'Firmada', '72275217', 'INS-2026-09-003'),
  ('BOL-202609-0015', 'Firmada', '43510587', 'INS-2026-09-003'),
  ('BOL-202609-0016', 'Firmada', '71271679', 'INS-2026-09-003'),
  ('BOL-202609-0017', 'Firmada', '74338638', 'INS-2026-09-003'),
  ('BOL-202609-0018', 'Firmada', '41406079', 'INS-2026-09-004');
INSERT INTO BOLETA_PAGO (Num_boleta, Firma_trabajador, DNI, Num_inspeccion) VALUES
  ('BOL-202609-0019', 'Firmada', '72387158', 'INS-2026-09-004'),
  ('BOL-202609-0020', 'Firmada', '46695880', 'INS-2026-09-004'),
  ('BOL-202609-0021', 'Firmada', '74743120', 'INS-2026-09-004'),
  ('BOL-202609-0022', 'Firmada', '71383122', 'INS-2026-09-004'),
  ('BOL-202609-0023', 'Firmada', '45950756', 'INS-2026-09-005'),
  ('BOL-202609-0024', 'Firmada', '42219803', 'INS-2026-09-005'),
  ('BOL-202609-0025', 'Firmada', '72502438', 'INS-2026-09-005'),
  ('BOL-202609-0026', 'Firmada', '44423950', 'INS-2026-09-005'),
  ('BOL-202609-0027', 'Firmada', '45768741', 'INS-2026-09-005'),
  ('BOL-202609-0028', 'Firmada', '72493759', 'INS-2026-09-005'),
  ('BOL-202609-0029', 'Firmada', '74368538', 'INS-2026-09-005'),
  ('BOL-202609-0030', 'Firmada', '76581112', 'INS-2026-09-006'),
  ('BOL-202609-0031', 'Firmada', '47165365', 'INS-2026-09-006'),
  ('BOL-202609-0032', 'Firmada', '40131777', 'INS-2026-09-006'),
  ('BOL-202609-0033', 'Firmada', '71873068', 'INS-2026-09-006'),
  ('BOL-202609-0034', 'Firmada', '70079389', 'INS-2026-09-006'),
  ('BOL-202609-0035', 'Firmada', '45457987', 'INS-2026-09-006'),
  ('BOL-202609-0036', 'Firmada', '45731722', 'INS-2026-09-006'),
  ('BOL-202609-0037', 'Firmada', '42163254', 'INS-2026-09-007'),
  ('BOL-202609-0038', 'Firmada', '40177862', 'INS-2026-09-007'),
  ('BOL-202609-0039', 'Firmada', '43708948', 'INS-2026-09-007'),
  ('BOL-202609-0040', 'Firmada', '46625414', 'INS-2026-09-007'),
  ('BOL-202609-0041', 'Firmada', '74813733', 'INS-2026-09-007'),
  ('BOL-202609-0042', 'Firmada', '45414231', 'INS-2026-09-007'),
  ('BOL-202609-0043', 'Firmada', '42240425', 'INS-2026-09-007'),
  ('BOL-202609-0044', 'Firmada', '71518007', 'INS-2026-09-007'),
  ('BOL-202609-0045', 'Firmada', '73206828', 'INS-2026-09-008'),
  ('BOL-202609-0046', 'Firmada', '48126126', 'INS-2026-09-008'),
  ('BOL-202609-0047', 'Firmada', '73596879', 'INS-2026-09-008'),
  ('BOL-202609-0048', 'Firmada', '47979758', 'INS-2026-09-008'),
  ('BOL-202609-0049', 'Firmada', '47336743', 'INS-2026-09-008'),
  ('BOL-202609-0050', 'Firmada', '40865140', 'INS-2026-09-008'),
  ('BOL-202609-0051', 'Firmada', '43364705', 'INS-2026-09-008'),
  ('BOL-202609-0052', 'Firmada', '73257171', 'INS-2026-09-009'),
  ('BOL-202609-0053', 'Firmada', '46500139', 'INS-2026-09-009'),
  ('BOL-202609-0054', 'Firmada', '73930805', 'INS-2026-09-009'),
  ('BOL-202609-0055', 'Firmada', '42812093', 'INS-2026-09-009'),
  ('BOL-202609-0056', 'Firmada', '73112728', 'INS-2026-09-009'),
  ('BOL-202609-0057', 'Firmada', '75751651', 'INS-2026-09-009'),
  ('BOL-202609-0058', 'Firmada', '47388246', 'INS-2026-09-009'),
  ('BOL-202609-0059', 'No firmada', '71815739', 'INS-2026-09-010'),
  ('BOL-202609-0060', 'Firmada', '43324473', 'INS-2026-09-010'),
  ('BOL-202609-0061', 'Firmada', '73928916', 'INS-2026-09-010'),
  ('BOL-202609-0062', 'Firmada', '46352975', 'INS-2026-09-010'),
  ('BOL-202609-0063', 'Firmada', '46230283', 'INS-2026-09-010'),
  ('BOL-202609-0064', 'Firmada', '40752228', 'INS-2026-09-011'),
  ('BOL-202609-0065', 'Firmada', '74002617', 'INS-2026-09-011'),
  ('BOL-202609-0066', 'Firmada', '40908215', 'INS-2026-09-011'),
  ('BOL-202609-0067', 'Firmada', '75587395', 'INS-2026-09-011'),
  ('BOL-202609-0068', 'Firmada', '71905242', 'INS-2026-09-011'),
  ('BOL-202609-0069', 'Firmada', '48299424', 'INS-2026-09-012'),
  ('BOL-202609-0070', 'Firmada', '75955639', 'INS-2026-09-012'),
  ('BOL-202609-0071', 'Firmada', '70180423', 'INS-2026-09-012'),
  ('BOL-202609-0072', 'Firmada', '70907576', 'INS-2026-09-012'),
  ('BOL-202609-0073', 'Firmada', '72315353', 'INS-2026-09-012'),
  ('BOL-202609-0074', 'Firmada', '71342606', 'INS-2026-09-012'),
  ('BOL-202609-0075', 'Firmada', '72015528', 'INS-2026-09-012'),
  ('BOL-202609-0076', 'Firmada', '40065537', 'INS-2026-09-012'),
  ('BOL-202609-0077', 'Firmada', '76652718', 'INS-2026-09-013'),
  ('BOL-202609-0078', 'Firmada', '76006912', 'INS-2026-09-013'),
  ('BOL-202609-0079', 'Firmada', '71540558', 'INS-2026-09-013'),
  ('BOL-202609-0080', 'Firmada', '43751737', 'INS-2026-09-013'),
  ('BOL-202609-0081', 'Firmada', '44376048', 'INS-2026-09-013'),
  ('BOL-202609-0082', 'Firmada', '43761680', 'INS-2026-09-013'),
  ('BOL-202609-0083', 'Firmada', '44441759', 'INS-2026-09-014'),
  ('BOL-202609-0084', 'Firmada', '74915035', 'INS-2026-09-014'),
  ('BOL-202609-0085', 'Firmada', '46476573', 'INS-2026-09-014'),
  ('BOL-202609-0086', 'Firmada', '71728206', 'INS-2026-09-014'),
  ('BOL-202609-0087', 'Firmada', '71675500', 'INS-2026-09-014'),
  ('BOL-202609-0088', 'Firmada', '71012734', 'INS-2026-09-014'),
  ('BOL-202609-0089', 'Firmada', '42982232', 'INS-2026-09-014'),
  ('BOL-202609-0090', 'Firmada', '72879685', 'INS-2026-09-014'),
  ('BOL-202609-0091', 'Firmada', '40916276', 'INS-2026-09-015'),
  ('BOL-202609-0092', 'Firmada', '73963527', 'INS-2026-09-015'),
  ('BOL-202609-0093', 'Firmada', '43892914', 'INS-2026-09-015'),
  ('BOL-202609-0094', 'Firmada', '75444200', 'INS-2026-09-015'),
  ('BOL-202609-0095', 'Firmada', '40644902', 'INS-2026-09-015'),
  ('BOL-202609-0096', 'Firmada', '45520843', 'INS-2026-09-015'),
  ('BOL-202609-0097', 'Firmada', '76965074', 'INS-2026-09-015'),
  ('BOL-202609-0098', 'Firmada', '41579947', 'INS-2026-09-015'),
  ('BOL-202609-0099', 'Firmada', '73899177', 'INS-2026-09-016'),
  ('BOL-202609-0100', 'Firmada', '46724988', 'INS-2026-09-016'),
  ('BOL-202609-0101', 'Firmada', '45023399', 'INS-2026-09-016'),
  ('BOL-202609-0102', 'Firmada', '74553619', 'INS-2026-09-016'),
  ('BOL-202609-0103', 'Firmada', '73363762', 'INS-2026-09-016'),
  ('BOL-202609-0104', 'Firmada', '71080618', 'INS-2026-09-016');

-- DECLARACION_JURADA (7 filas)
INSERT INTO DECLARACION_JURADA (Num_declaracion, Fecha_compromiso_pago, Num_inspeccion) VALUES
  ('DJ-202603-001', '2026-04-28', 'INS-2026-03-011'),
  ('DJ-202605-001', '2026-06-22', 'INS-2026-05-012'),
  ('DJ-202607-001', '2026-08-20', 'INS-2026-07-012'),
  ('DJ-202607-002', '2026-08-25', 'INS-2026-07-014'),
  ('DJ-202607-003', '2026-10-05', 'INS-2026-07-016'),
  ('DJ-202608-001', '2026-11-06', 'INS-2026-08-014'),
  ('DJ-202609-001', '2026-10-30', 'INS-2026-09-014');

-- DECLARA (1768 filas)
INSERT INTO DECLARA (Num_inspeccion, Cod_obligacion, Monto_declarado, Monto_pagado, Mora, Fecha_pago) VALUES
  ('INS-2026-01-001', '1.1', 0.00, 0.00, NULL, '2026-02-16'),
  ('INS-2026-01-001', '1.2', 727.82, 727.82, NULL, '2026-02-14'),
  ('INS-2026-01-001', '1.3', 1150.35, 1150.35, NULL, '2026-02-14'),
  ('INS-2026-01-001', '1.4', 157.21, 157.21, NULL, '2026-02-17'),
  ('INS-2026-01-001', '1.5', 90.75, 90.75, NULL, '2026-02-15'),
  ('INS-2026-01-001', '1.6', 498.48, 498.48, NULL, '2026-02-14'),
  ('INS-2026-01-001', '1.7', 1137.57, 1137.57, NULL, '2026-02-16'),
  ('INS-2026-01-001', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-01-001', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-01-001', '1.10', NULL, NULL, NULL, NULL),
  ('INS-2026-01-001', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-01-001', '1.12', 76.69, 76.69, NULL, '2026-02-17'),
  ('INS-2026-01-001', '1.13', NULL, NULL, NULL, NULL),
  ('INS-2026-01-002', '1.1', 4673.63, 4673.63, NULL, '2026-02-12'),
  ('INS-2026-01-002', '1.2', 2126.57, 2126.57, NULL, '2026-02-13'),
  ('INS-2026-01-002', '1.3', 3107.87, 3107.87, NULL, '2026-02-12'),
  ('INS-2026-01-002', '1.4', 424.74, 424.74, NULL, '2026-02-11'),
  ('INS-2026-01-002', '1.5', 245.18, 245.18, NULL, '2026-02-10'),
  ('INS-2026-01-002', '1.6', 1346.74, 1346.74, NULL, '2026-02-12'),
  ('INS-2026-01-002', '1.7', 3073.34, 3073.34, NULL, '2026-02-10'),
  ('INS-2026-01-002', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-01-002', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-01-002', '1.10', 237.50, 237.50, NULL, '2026-02-10'),
  ('INS-2026-01-002', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-01-002', '1.12', 207.19, 207.19, NULL, '2026-02-13'),
  ('INS-2026-01-002', '1.13', NULL, NULL, NULL, NULL),
  ('INS-2026-01-003', '1.1', 4842.52, 4842.52, NULL, '2026-02-12'),
  ('INS-2026-01-003', '1.2', 2001.94, 2001.94, NULL, '2026-02-13'),
  ('INS-2026-01-003', '1.3', 3167.50, 3167.50, NULL, '2026-02-12'),
  ('INS-2026-01-003', '1.4', 432.89, 432.89, NULL, '2026-02-10'),
  ('INS-2026-01-003', '1.5', 249.88, 249.88, NULL, '2026-02-13'),
  ('INS-2026-01-003', '1.6', 1372.58, 1372.58, NULL, '2026-02-12'),
  ('INS-2026-01-003', '1.7', 3132.30, 3132.30, NULL, '2026-02-11'),
  ('INS-2026-01-003', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-01-003', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-01-003', '1.10', NULL, NULL, NULL, NULL),
  ('INS-2026-01-003', '1.11', 263.96, 263.96, NULL, '2026-02-13'),
  ('INS-2026-01-003', '1.12', 211.17, 211.17, NULL, '2026-02-13'),
  ('INS-2026-01-003', '1.13', NULL, NULL, NULL, NULL),
  ('INS-2026-01-004', '1.1', 8667.24, 8667.24, NULL, '2026-02-15'),
  ('INS-2026-01-004', '1.2', 2502.54, 2502.54, NULL, '2026-02-17'),
  ('INS-2026-01-004', '1.3', 2947.85, 2947.85, NULL, '2026-02-15'),
  ('INS-2026-01-004', '1.4', 402.87, 402.87, NULL, '2026-02-14'),
  ('INS-2026-01-004', '1.5', 232.55, 232.55, NULL, '2026-02-17'),
  ('INS-2026-01-004', '1.6', 1277.40, 1277.40, NULL, '2026-02-14'),
  ('INS-2026-01-004', '1.7', 2915.10, 2915.10, NULL, '2026-02-15'),
  ('INS-2026-01-004', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-01-004', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-01-004', '1.10', NULL, NULL, NULL, NULL),
  ('INS-2026-01-004', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-01-004', '1.12', 196.52, 196.52, NULL, '2026-02-16'),
  ('INS-2026-01-004', '1.13', 131.02, 131.02, NULL, '2026-02-14'),
  ('INS-2026-01-005', '1.1', 0.00, 0.00, NULL, '2026-02-16'),
  ('INS-2026-01-005', '1.2', 638.92, 638.92, NULL, '2026-02-16'),
  ('INS-2026-01-005', '1.3', 1869.05, 1869.05, NULL, '2026-02-16'),
  ('INS-2026-01-005', '1.4', 255.44, 255.44, NULL, '2026-02-16'),
  ('INS-2026-01-005', '1.5', 147.45, 147.45, NULL, '2026-02-17'),
  ('INS-2026-01-005', '1.6', 809.92, 809.92, NULL, '2026-02-15'),
  ('INS-2026-01-005', '1.7', 1848.28, 1848.28, NULL, '2026-02-16'),
  ('INS-2026-01-005', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-01-005', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-01-005', '1.10', NULL, NULL, NULL, NULL),
  ('INS-2026-01-005', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-01-005', '1.12', 124.60, 124.60, NULL, '2026-02-14'),
  ('INS-2026-01-005', '1.13', NULL, NULL, NULL, NULL),
  ('INS-2026-01-006', '1.1', 4445.04, 4445.04, NULL, '2026-02-12'),
  ('INS-2026-01-006', '1.2', 1380.64, 1380.64, NULL, '2026-02-13'),
  ('INS-2026-01-006', '1.3', 1625.79, 1625.79, NULL, '2026-02-15'),
  ('INS-2026-01-006', '1.4', 222.19, 222.19, NULL, '2026-02-14'),
  ('INS-2026-01-006', '1.5', 128.26, 128.26, NULL, '2026-02-15'),
  ('INS-2026-01-006', '1.6', 704.51, 704.51, NULL, '2026-02-15'),
  ('INS-2026-01-006', '1.7', 1607.73, 1607.73, NULL, '2026-02-14'),
  ('INS-2026-01-006', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-01-006', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-01-006', '1.10', NULL, NULL, NULL, NULL),
  ('INS-2026-01-006', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-01-006', '1.12', 108.39, 108.39, NULL, '2026-02-13'),
  ('INS-2026-01-006', '1.13', NULL, NULL, NULL, NULL),
  ('INS-2026-01-007', '1.1', 2398.76, 2398.76, NULL, '2026-02-17'),
  ('INS-2026-01-007', '1.2', 984.91, 984.91, NULL, '2026-02-16'),
  ('INS-2026-01-007', '1.3', 1776.70, 1776.70, NULL, '2026-02-17'),
  ('INS-2026-01-007', '1.4', 242.82, 242.82, NULL, '2026-02-19'),
  ('INS-2026-01-007', '1.5', 140.16, 140.16, NULL, '2026-02-17'),
  ('INS-2026-01-007', '1.6', 769.90, 769.90, NULL, '2026-02-19'),
  ('INS-2026-01-007', '1.7', 1756.96, 1756.96, NULL, '2026-02-17'),
  ('INS-2026-01-007', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-01-007', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-01-007', '1.10', NULL, NULL, NULL, NULL),
  ('INS-2026-01-007', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-01-007', '1.12', 118.45, 118.45, NULL, '2026-02-17'),
  ('INS-2026-01-007', '1.13', 78.96, 78.96, NULL, '2026-02-19'),
  ('INS-2026-01-008', '1.1', 2414.01, 2414.01, NULL, '2026-02-13'),
  ('INS-2026-01-008', '1.2', 1242.42, 1242.42, NULL, '2026-02-14'),
  ('INS-2026-01-008', '1.3', 1731.81, 1731.81, NULL, '2026-02-12'),
  ('INS-2026-01-008', '1.4', 236.68, 236.68, NULL, '2026-02-13'),
  ('INS-2026-01-008', '1.5', 136.62, 136.62, NULL, '2026-02-15'),
  ('INS-2026-01-008', '1.6', 750.45, 750.45, NULL, '2026-02-13'),
  ('INS-2026-01-008', '1.7', 1712.56, 1712.56, NULL, '2026-02-13'),
  ('INS-2026-01-008', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-01-008', '1.9', NULL, NULL, NULL, NULL);
INSERT INTO DECLARA (Num_inspeccion, Cod_obligacion, Monto_declarado, Monto_pagado, Mora, Fecha_pago) VALUES
  ('INS-2026-01-008', '1.10', NULL, NULL, NULL, NULL),
  ('INS-2026-01-008', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-01-008', '1.12', 115.45, 115.45, NULL, '2026-02-14'),
  ('INS-2026-01-008', '1.13', NULL, NULL, NULL, NULL),
  ('INS-2026-01-009', '1.1', 3098.40, 3098.40, NULL, '2026-02-12'),
  ('INS-2026-01-009', '1.2', 955.75, 955.75, NULL, '2026-02-10'),
  ('INS-2026-01-009', '1.3', 2189.27, 2189.27, NULL, '2026-02-11'),
  ('INS-2026-01-009', '1.4', 299.20, 299.20, NULL, '2026-02-11'),
  ('INS-2026-01-009', '1.5', 172.71, 172.71, NULL, '2026-02-13'),
  ('INS-2026-01-009', '1.6', 948.68, 948.68, NULL, '2026-02-11'),
  ('INS-2026-01-009', '1.7', 2164.94, 2164.94, NULL, '2026-02-13'),
  ('INS-2026-01-009', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-01-009', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-01-009', '1.10', NULL, NULL, NULL, NULL),
  ('INS-2026-01-009', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-01-009', '1.12', 145.95, 145.95, NULL, '2026-02-12'),
  ('INS-2026-01-009', '1.13', NULL, NULL, NULL, NULL),
  ('INS-2026-01-010', '1.1', 3018.73, 3018.73, NULL, '2026-02-17'),
  ('INS-2026-01-010', '1.2', 841.20, 841.20, NULL, '2026-02-18'),
  ('INS-2026-01-010', '1.3', 1495.84, 1495.84, NULL, '2026-02-18'),
  ('INS-2026-01-010', '1.4', 204.43, 204.43, NULL, '2026-02-16'),
  ('INS-2026-01-010', '1.5', 118.01, 118.01, NULL, '2026-02-17'),
  ('INS-2026-01-010', '1.6', 648.20, 648.20, NULL, '2026-02-17'),
  ('INS-2026-01-010', '1.7', 1479.22, 1479.22, NULL, '2026-02-17'),
  ('INS-2026-01-010', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-01-010', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-01-010', '1.10', NULL, NULL, NULL, NULL),
  ('INS-2026-01-010', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-01-010', '1.12', 99.72, 99.72, NULL, '2026-02-17'),
  ('INS-2026-01-010', '1.13', 66.48, 66.48, NULL, '2026-02-18'),
  ('INS-2026-01-011', '1.1', 6223.19, 6223.19, NULL, '2026-02-13'),
  ('INS-2026-01-011', '1.2', 1670.14, 1670.14, NULL, '2026-02-14'),
  ('INS-2026-01-011', '1.3', 2881.24, 2881.24, NULL, '2026-02-13'),
  ('INS-2026-01-011', '1.4', 393.77, 393.77, NULL, '2026-02-14'),
  ('INS-2026-01-011', '1.5', 227.30, 227.30, NULL, '2026-02-14'),
  ('INS-2026-01-011', '1.6', 1248.54, 1248.54, NULL, '2026-02-14'),
  ('INS-2026-01-011', '1.7', 2849.22, 2849.22, NULL, '2026-02-11'),
  ('INS-2026-01-011', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-01-011', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-01-011', '1.10', NULL, NULL, NULL, NULL),
  ('INS-2026-01-011', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-01-011', '1.12', 192.08, 192.08, NULL, '2026-02-12'),
  ('INS-2026-01-011', '1.13', NULL, NULL, NULL, NULL),
  ('INS-2026-02-001', '1.1', 1833.74, 1833.74, NULL, '2026-03-12'),
  ('INS-2026-02-001', '1.2', 946.17, 946.17, NULL, '2026-03-13'),
  ('INS-2026-02-001', '1.3', 2103.03, 2103.03, NULL, '2026-03-13'),
  ('INS-2026-02-001', '1.4', 287.41, 287.41, NULL, '2026-03-10'),
  ('INS-2026-02-001', '1.5', 165.91, 165.91, NULL, '2026-03-11'),
  ('INS-2026-02-001', '1.6', 911.31, 911.31, NULL, '2026-03-10'),
  ('INS-2026-02-001', '1.7', 2079.66, 2079.66, NULL, '2026-03-12'),
  ('INS-2026-02-001', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-02-001', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-02-001', '1.10', NULL, NULL, NULL, NULL),
  ('INS-2026-02-001', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-02-001', '1.12', 140.20, 140.20, NULL, '2026-03-12'),
  ('INS-2026-02-001', '1.13', NULL, NULL, NULL, NULL),
  ('INS-2026-02-002', '1.1', 2331.19, 2331.19, NULL, '2026-03-10'),
  ('INS-2026-02-002', '1.2', 1348.48, 1348.48, NULL, '2026-03-10'),
  ('INS-2026-02-002', '1.3', 2348.85, 2348.85, NULL, '2026-03-11'),
  ('INS-2026-02-002', '1.4', 321.01, 321.01, NULL, '2026-03-12'),
  ('INS-2026-02-002', '1.5', 185.30, 185.30, NULL, '2026-03-11'),
  ('INS-2026-02-002', '1.6', 1017.84, 1017.84, NULL, '2026-03-12'),
  ('INS-2026-02-002', '1.7', 2322.76, 2322.76, NULL, '2026-03-13'),
  ('INS-2026-02-002', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-02-002', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-02-002', '1.10', 145.00, 145.00, NULL, '2026-03-10'),
  ('INS-2026-02-002', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-02-002', '1.12', 156.59, 156.59, NULL, '2026-03-12'),
  ('INS-2026-02-002', '1.13', NULL, NULL, NULL, NULL),
  ('INS-2026-02-003', '1.1', 0.00, 0.00, NULL, '2026-03-15'),
  ('INS-2026-02-003', '1.2', 730.96, 730.96, NULL, '2026-03-15'),
  ('INS-2026-02-003', '1.3', 1178.65, 1178.65, NULL, '2026-03-14'),
  ('INS-2026-02-003', '1.4', 161.08, 161.08, NULL, '2026-03-16'),
  ('INS-2026-02-003', '1.5', 92.98, 92.98, NULL, '2026-03-17'),
  ('INS-2026-02-003', '1.6', 510.75, 510.75, NULL, '2026-03-17'),
  ('INS-2026-02-003', '1.7', 1165.56, 1165.56, NULL, '2026-03-17'),
  ('INS-2026-02-003', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-02-003', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-02-003', '1.10', NULL, NULL, NULL, NULL),
  ('INS-2026-02-003', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-02-003', '1.12', 78.58, 78.58, NULL, '2026-03-16'),
  ('INS-2026-02-003', '1.13', NULL, NULL, NULL, NULL),
  ('INS-2026-02-004', '1.1', 4773.95, 4773.95, NULL, '2026-03-14'),
  ('INS-2026-02-004', '1.2', 1238.53, 1238.53, NULL, '2026-03-14'),
  ('INS-2026-02-004', '1.3', 1696.78, 1696.78, NULL, '2026-03-13'),
  ('INS-2026-02-004', '1.4', 231.89, 231.89, NULL, '2026-03-12'),
  ('INS-2026-02-004', '1.5', 133.86, 133.86, NULL, '2026-03-14'),
  ('INS-2026-02-004', '1.6', 735.27, 735.27, NULL, '2026-03-12'),
  ('INS-2026-02-004', '1.7', 1677.93, 1677.93, NULL, '2026-03-12'),
  ('INS-2026-02-004', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-02-004', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-02-004', '1.10', NULL, NULL, NULL, NULL),
  ('INS-2026-02-004', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-02-004', '1.12', 113.12, 113.12, NULL, '2026-03-14'),
  ('INS-2026-02-004', '1.13', NULL, NULL, NULL, NULL),
  ('INS-2026-02-005', '1.1', 3603.64, 3603.64, NULL, '2026-03-13'),
  ('INS-2026-02-005', '1.2', 2123.45, 2123.45, NULL, '2026-03-10'),
  ('INS-2026-02-005', '1.3', 3079.76, 3079.76, NULL, '2026-03-10'),
  ('INS-2026-02-005', '1.4', 420.90, 420.90, NULL, '2026-03-11'),
  ('INS-2026-02-005', '1.5', 242.96, 242.96, NULL, '2026-03-10');
INSERT INTO DECLARA (Num_inspeccion, Cod_obligacion, Monto_declarado, Monto_pagado, Mora, Fecha_pago) VALUES
  ('INS-2026-02-005', '1.6', 1334.56, 1334.56, NULL, '2026-03-13'),
  ('INS-2026-02-005', '1.7', 3045.54, 3045.54, NULL, '2026-03-10'),
  ('INS-2026-02-005', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-02-005', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-02-005', '1.10', 237.50, 237.50, NULL, '2026-03-13'),
  ('INS-2026-02-005', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-02-005', '1.12', 205.32, 205.32, NULL, '2026-03-10'),
  ('INS-2026-02-005', '1.13', NULL, NULL, NULL, NULL),
  ('INS-2026-02-006', '1.1', 7872.19, 7872.19, NULL, '2026-03-17'),
  ('INS-2026-02-006', '1.2', 2281.38, 2281.38, NULL, '2026-03-18'),
  ('INS-2026-02-006', '1.3', 2813.69, 2813.69, NULL, '2026-03-18'),
  ('INS-2026-02-006', '1.4', 384.54, 384.54, NULL, '2026-03-18'),
  ('INS-2026-02-006', '1.5', 221.97, 221.97, NULL, '2026-03-19'),
  ('INS-2026-02-006', '1.6', 1219.27, 1219.27, NULL, '2026-03-16'),
  ('INS-2026-02-006', '1.7', 2782.43, 2782.43, NULL, '2026-03-19'),
  ('INS-2026-02-006', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-02-006', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-02-006', '1.10', 262.50, 262.50, NULL, '2026-03-18'),
  ('INS-2026-02-006', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-02-006', '1.12', 187.58, 187.58, NULL, '2026-03-19'),
  ('INS-2026-02-006', '1.13', NULL, NULL, NULL, NULL),
  ('INS-2026-02-007', '1.1', 3131.42, 3131.42, NULL, '2026-03-11'),
  ('INS-2026-02-007', '1.2', 1669.46, 1669.46, NULL, '2026-03-12'),
  ('INS-2026-02-007', '1.3', 2875.13, 2875.13, NULL, '2026-03-11'),
  ('INS-2026-02-007', '1.4', 392.93, 392.93, NULL, '2026-03-11'),
  ('INS-2026-02-007', '1.5', 226.82, 226.82, NULL, '2026-03-13'),
  ('INS-2026-02-007', '1.6', 1245.89, 1245.89, NULL, '2026-03-13'),
  ('INS-2026-02-007', '1.7', 2843.19, 2843.19, NULL, '2026-03-11'),
  ('INS-2026-02-007', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-02-007', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-02-007', '1.10', NULL, NULL, NULL, NULL),
  ('INS-2026-02-007', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-02-007', '1.12', 191.68, 191.68, NULL, '2026-03-14'),
  ('INS-2026-02-007', '1.13', NULL, NULL, NULL, NULL),
  ('INS-2026-02-008', '1.1', 0.00, 0.00, NULL, '2026-03-14'),
  ('INS-2026-02-008', '1.2', 635.70, 635.70, NULL, '2026-03-15'),
  ('INS-2026-02-008', '1.3', 1840.08, 1840.08, NULL, '2026-03-17'),
  ('INS-2026-02-008', '1.4', 251.48, 251.48, NULL, '2026-03-15'),
  ('INS-2026-02-008', '1.5', 145.16, 145.16, NULL, '2026-03-15'),
  ('INS-2026-02-008', '1.6', 797.37, 797.37, NULL, '2026-03-15'),
  ('INS-2026-02-008', '1.7', 1819.63, 1819.63, NULL, '2026-03-16'),
  ('INS-2026-02-008', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-02-008', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-02-008', '1.10', NULL, NULL, NULL, NULL),
  ('INS-2026-02-008', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-02-008', '1.12', 122.67, 122.67, NULL, '2026-03-15'),
  ('INS-2026-02-008', '1.13', NULL, NULL, NULL, NULL),
  ('INS-2026-02-009', '1.1', 6568.99, 6568.99, NULL, '2026-03-17'),
  ('INS-2026-02-009', '1.2', 2496.14, 2496.14, NULL, '2026-03-14'),
  ('INS-2026-02-009', '1.3', 2890.29, 2890.29, NULL, '2026-03-16'),
  ('INS-2026-02-009', '1.4', 395.01, 395.01, NULL, '2026-03-17'),
  ('INS-2026-02-009', '1.5', 228.01, 228.01, NULL, '2026-03-14'),
  ('INS-2026-02-009', '1.6', 1252.46, 1252.46, NULL, '2026-03-14'),
  ('INS-2026-02-009', '1.7', 2858.18, 2858.18, NULL, '2026-03-14'),
  ('INS-2026-02-009', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-02-009', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-02-009', '1.10', NULL, NULL, NULL, NULL),
  ('INS-2026-02-009', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-02-009', '1.12', 192.69, 192.69, NULL, '2026-03-16'),
  ('INS-2026-02-009', '1.13', 128.46, 128.46, NULL, '2026-03-14'),
  ('INS-2026-02-010', '1.1', 3613.90, 3613.90, NULL, '2026-03-19'),
  ('INS-2026-02-010', '1.2', 989.55, 989.55, NULL, '2026-03-17'),
  ('INS-2026-02-010', '1.3', 1818.47, 1818.47, NULL, '2026-03-16'),
  ('INS-2026-02-010', '1.4', 248.52, 248.52, NULL, '2026-03-18'),
  ('INS-2026-02-010', '1.5', 143.46, 143.46, NULL, '2026-03-16'),
  ('INS-2026-02-010', '1.6', 788.00, 788.00, NULL, '2026-03-16'),
  ('INS-2026-02-010', '1.7', 1798.26, 1798.26, NULL, '2026-03-17'),
  ('INS-2026-02-010', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-02-010', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-02-010', '1.10', NULL, NULL, NULL, NULL),
  ('INS-2026-02-010', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-02-010', '1.12', 121.23, 121.23, NULL, '2026-03-17'),
  ('INS-2026-02-010', '1.13', 80.82, 80.82, NULL, '2026-03-16'),
  ('INS-2026-02-011', '1.1', 6907.84, 6907.84, NULL, '2026-03-12'),
  ('INS-2026-02-011', '1.2', 2015.35, 2015.35, NULL, '2026-03-11'),
  ('INS-2026-02-011', '1.3', 3288.19, 3288.19, NULL, '2026-03-12'),
  ('INS-2026-02-011', '1.4', 449.39, 449.39, NULL, '2026-03-13'),
  ('INS-2026-02-011', '1.5', 259.40, 259.40, NULL, '2026-03-13'),
  ('INS-2026-02-011', '1.6', 1424.88, 1424.88, NULL, '2026-03-11'),
  ('INS-2026-02-011', '1.7', 3251.65, 3251.65, NULL, '2026-03-13'),
  ('INS-2026-02-011', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-02-011', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-02-011', '1.10', NULL, NULL, NULL, NULL),
  ('INS-2026-02-011', '1.11', 274.02, 274.02, NULL, '2026-03-11'),
  ('INS-2026-02-011', '1.12', 219.21, 219.21, NULL, '2026-03-12'),
  ('INS-2026-02-011', '1.13', NULL, NULL, NULL, NULL),
  ('INS-2026-02-012', '1.1', 1782.14, 1782.14, NULL, '2026-03-17'),
  ('INS-2026-02-012', '1.2', 844.42, 844.42, NULL, '2026-03-16'),
  ('INS-2026-02-012', '1.3', 1524.81, 1524.81, NULL, '2026-03-18'),
  ('INS-2026-02-012', '1.4', 208.39, 208.39, NULL, '2026-03-16'),
  ('INS-2026-02-012', '1.5', 120.29, 120.29, NULL, '2026-03-19'),
  ('INS-2026-02-012', '1.6', 660.75, 660.75, NULL, '2026-03-16'),
  ('INS-2026-02-012', '1.7', 1507.87, 1507.87, NULL, '2026-03-16'),
  ('INS-2026-02-012', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-02-012', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-02-012', '1.10', NULL, NULL, NULL, NULL),
  ('INS-2026-02-012', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-02-012', '1.12', 101.65, 101.65, NULL, '2026-03-18'),
  ('INS-2026-02-012', '1.13', 67.77, 67.77, NULL, '2026-03-17'),
  ('INS-2026-02-013', '1.1', 2776.33, 2776.33, NULL, '2026-03-12');
INSERT INTO DECLARA (Num_inspeccion, Cod_obligacion, Monto_declarado, Monto_pagado, Mora, Fecha_pago) VALUES
  ('INS-2026-02-013', '1.2', 1380.66, 1380.66, NULL, '2026-03-12'),
  ('INS-2026-02-013', '1.3', 1625.95, 1625.95, NULL, '2026-03-13'),
  ('INS-2026-02-013', '1.4', 222.21, 222.21, NULL, '2026-03-12'),
  ('INS-2026-02-013', '1.5', 128.27, 128.27, NULL, '2026-03-13'),
  ('INS-2026-02-013', '1.6', 704.58, 704.58, NULL, '2026-03-13'),
  ('INS-2026-02-013', '1.7', 1607.89, 1607.89, NULL, '2026-03-14'),
  ('INS-2026-02-013', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-02-013', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-02-013', '1.10', NULL, NULL, NULL, NULL),
  ('INS-2026-02-013', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-02-013', '1.12', 108.40, 108.40, NULL, '2026-03-14'),
  ('INS-2026-02-013', '1.13', NULL, NULL, NULL, NULL),
  ('INS-2026-02-014', '1.1', 5873.83, 5873.83, NULL, '2026-03-18'),
  ('INS-2026-02-014', '1.2', 2277.90, 2277.90, NULL, '2026-03-19'),
  ('INS-2026-02-014', '1.3', 2782.32, 2782.32, NULL, '2026-03-19'),
  ('INS-2026-02-014', '1.4', 380.25, 380.25, NULL, '2026-03-19'),
  ('INS-2026-02-014', '1.5', 219.49, 219.49, NULL, '2026-03-16'),
  ('INS-2026-02-014', '1.6', 1205.67, 1205.67, NULL, '2026-03-18'),
  ('INS-2026-02-014', '1.7', 2751.41, 2751.41, NULL, '2026-03-19'),
  ('INS-2026-02-014', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-02-014', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-02-014', '1.10', 262.50, 262.50, NULL, '2026-03-19'),
  ('INS-2026-02-014', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-02-014', '1.12', 185.49, 185.49, NULL, '2026-03-17'),
  ('INS-2026-02-014', '1.13', NULL, NULL, NULL, NULL),
  ('INS-2026-03-001', '1.1', 1592.33, 1592.33, NULL, '2026-04-19'),
  ('INS-2026-03-001', '1.2', 988.67, 988.67, NULL, '2026-04-18'),
  ('INS-2026-03-001', '1.3', 1810.57, 1810.57, NULL, '2026-04-16'),
  ('INS-2026-03-001', '1.4', 247.45, 247.45, NULL, '2026-04-17'),
  ('INS-2026-03-001', '1.5', 142.83, 142.83, NULL, '2026-04-18'),
  ('INS-2026-03-001', '1.6', 784.58, 784.58, NULL, '2026-04-18'),
  ('INS-2026-03-001', '1.7', 1790.46, 1790.46, NULL, '2026-04-17'),
  ('INS-2026-03-001', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-03-001', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-03-001', '1.10', NULL, NULL, NULL, NULL),
  ('INS-2026-03-001', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-03-001', '1.12', 120.70, 120.70, NULL, '2026-04-16'),
  ('INS-2026-03-001', '1.13', 80.47, 80.47, NULL, '2026-04-17'),
  ('INS-2026-03-002', '1.1', 7232.48, 7232.48, NULL, '2026-04-12'),
  ('INS-2026-03-002', '1.2', 2007.89, 2007.89, NULL, '2026-04-12'),
  ('INS-2026-03-002', '1.3', 3221.05, 3221.05, NULL, '2026-04-10'),
  ('INS-2026-03-002', '1.4', 440.21, 440.21, NULL, '2026-04-13'),
  ('INS-2026-03-002', '1.5', 254.11, 254.11, NULL, '2026-04-11'),
  ('INS-2026-03-002', '1.6', 1395.79, 1395.79, NULL, '2026-04-13'),
  ('INS-2026-03-002', '1.7', 3185.26, 3185.26, NULL, '2026-04-13'),
  ('INS-2026-03-002', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-03-002', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-03-002', '1.10', NULL, NULL, NULL, NULL),
  ('INS-2026-03-002', '1.11', 268.42, 268.42, NULL, '2026-04-11'),
  ('INS-2026-03-002', '1.12', 214.74, 214.74, NULL, '2026-04-10'),
  ('INS-2026-03-002', '1.13', NULL, NULL, NULL, NULL),
  ('INS-2026-03-003', '1.1', 1852.09, 1852.09, NULL, '2026-04-16'),
  ('INS-2026-03-003', '1.2', 633.35, 633.35, NULL, '2026-04-17'),
  ('INS-2026-03-003', '1.3', 1312.66, 1312.66, NULL, '2026-04-14'),
  ('INS-2026-03-003', '1.4', 179.40, 179.40, NULL, '2026-04-14'),
  ('INS-2026-03-003', '1.5', 103.55, 103.55, NULL, '2026-04-15'),
  ('INS-2026-03-003', '1.6', 568.82, 568.82, NULL, '2026-04-15'),
  ('INS-2026-03-003', '1.7', 1298.07, 1298.07, NULL, '2026-04-14'),
  ('INS-2026-03-003', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-03-003', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-03-003', '1.10', NULL, NULL, NULL, NULL),
  ('INS-2026-03-003', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-03-003', '1.12', 87.51, 87.51, NULL, '2026-04-16'),
  ('INS-2026-03-003', '1.13', NULL, NULL, NULL, NULL),
  ('INS-2026-03-004', '1.1', 0.00, 0.00, NULL, '2026-04-15'),
  ('INS-2026-03-004', '1.2', 646.71, 646.71, NULL, '2026-04-15'),
  ('INS-2026-03-004', '1.3', 1939.18, 1939.18, NULL, '2026-04-17'),
  ('INS-2026-03-004', '1.4', 265.02, 265.02, NULL, '2026-04-17'),
  ('INS-2026-03-004', '1.5', 152.98, 152.98, NULL, '2026-04-16'),
  ('INS-2026-03-004', '1.6', 840.31, 840.31, NULL, '2026-04-15'),
  ('INS-2026-03-004', '1.7', 1917.63, 1917.63, NULL, '2026-04-17'),
  ('INS-2026-03-004', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-03-004', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-03-004', '1.10', NULL, NULL, NULL, NULL),
  ('INS-2026-03-004', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-03-004', '1.12', 129.28, 129.28, NULL, '2026-04-17'),
  ('INS-2026-03-004', '1.13', NULL, NULL, NULL, NULL),
  ('INS-2026-03-005', '1.1', 5259.77, 5259.77, NULL, '2026-04-11'),
  ('INS-2026-03-005', '1.2', 2137.85, 2137.85, NULL, '2026-04-10'),
  ('INS-2026-03-005', '1.3', 3209.39, 3209.39, NULL, '2026-04-13'),
  ('INS-2026-03-005', '1.4', 438.62, 438.62, NULL, '2026-04-11'),
  ('INS-2026-03-005', '1.5', 253.19, 253.19, NULL, '2026-04-11'),
  ('INS-2026-03-005', '1.6', 1390.74, 1390.74, NULL, '2026-04-12'),
  ('INS-2026-03-005', '1.7', 3173.73, 3173.73, NULL, '2026-04-10'),
  ('INS-2026-03-005', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-03-005', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-03-005', '1.10', 237.50, 237.50, NULL, '2026-04-10'),
  ('INS-2026-03-005', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-03-005', '1.12', 213.96, 213.96, NULL, '2026-04-13'),
  ('INS-2026-03-005', '1.13', NULL, NULL, NULL, NULL),
  ('INS-2026-03-006', '1.1', 4778.98, 4778.98, NULL, '2026-04-16'),
  ('INS-2026-03-006', '1.2', 2505.89, 2505.89, NULL, '2026-04-16'),
  ('INS-2026-03-006', '1.3', 2978.04, 2978.04, NULL, '2026-04-16'),
  ('INS-2026-03-006', '1.4', 407.00, 407.00, NULL, '2026-04-16'),
  ('INS-2026-03-006', '1.5', 234.93, 234.93, NULL, '2026-04-14'),
  ('INS-2026-03-006', '1.6', 1290.48, 1290.48, NULL, '2026-04-17'),
  ('INS-2026-03-006', '1.7', 2944.95, 2944.95, NULL, '2026-04-14'),
  ('INS-2026-03-006', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-03-006', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-03-006', '1.10', NULL, NULL, NULL, NULL);
INSERT INTO DECLARA (Num_inspeccion, Cod_obligacion, Monto_declarado, Monto_pagado, Mora, Fecha_pago) VALUES
  ('INS-2026-03-006', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-03-006', '1.12', 198.54, 198.54, NULL, '2026-04-17'),
  ('INS-2026-03-006', '1.13', 132.36, 132.36, NULL, '2026-04-14'),
  ('INS-2026-03-007', '1.1', 4598.50, 4598.50, NULL, '2026-04-15'),
  ('INS-2026-03-007', '1.2', 1235.95, 1235.95, NULL, '2026-04-15'),
  ('INS-2026-03-007', '1.3', 1673.57, 1673.57, NULL, '2026-04-13'),
  ('INS-2026-03-007', '1.4', 228.72, 228.72, NULL, '2026-04-14'),
  ('INS-2026-03-007', '1.5', 132.03, 132.03, NULL, '2026-04-14'),
  ('INS-2026-03-007', '1.6', 725.22, 725.22, NULL, '2026-04-15'),
  ('INS-2026-03-007', '1.7', 1654.98, 1654.98, NULL, '2026-04-15'),
  ('INS-2026-03-007', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-03-007', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-03-007', '1.10', NULL, NULL, NULL, NULL),
  ('INS-2026-03-007', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-03-007', '1.12', 111.57, 111.57, NULL, '2026-04-14'),
  ('INS-2026-03-007', '1.13', NULL, NULL, NULL, NULL),
  ('INS-2026-03-008', '1.1', 4338.37, 4338.37, NULL, '2026-04-13'),
  ('INS-2026-03-008', '1.2', 1678.89, 1678.89, NULL, '2026-04-14'),
  ('INS-2026-03-008', '1.3', 2960.01, 2960.01, NULL, '2026-04-11'),
  ('INS-2026-03-008', '1.4', 404.54, 404.54, NULL, '2026-04-13'),
  ('INS-2026-03-008', '1.5', 233.51, 233.51, NULL, '2026-04-11'),
  ('INS-2026-03-008', '1.6', 1282.67, 1282.67, NULL, '2026-04-13'),
  ('INS-2026-03-008', '1.7', 2927.12, 2927.12, NULL, '2026-04-13'),
  ('INS-2026-03-008', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-03-008', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-03-008', '1.10', NULL, NULL, NULL, NULL),
  ('INS-2026-03-008', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-03-008', '1.12', 197.33, 197.33, NULL, '2026-04-14'),
  ('INS-2026-03-008', '1.13', NULL, NULL, NULL, NULL),
  ('INS-2026-03-009', '1.1', 7557.02, 7557.02, NULL, '2026-04-17'),
  ('INS-2026-03-009', '1.2', 2288.17, 2288.17, NULL, '2026-04-17'),
  ('INS-2026-03-009', '1.3', 2874.82, 2874.82, NULL, '2026-04-19'),
  ('INS-2026-03-009', '1.4', 392.89, 392.89, NULL, '2026-04-16'),
  ('INS-2026-03-009', '1.5', 226.79, 226.79, NULL, '2026-04-17'),
  ('INS-2026-03-009', '1.6', 1245.76, 1245.76, NULL, '2026-04-18'),
  ('INS-2026-03-009', '1.7', 2842.88, 2842.88, NULL, '2026-04-18'),
  ('INS-2026-03-009', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-03-009', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-03-009', '1.10', 262.50, 262.50, NULL, '2026-04-18'),
  ('INS-2026-03-009', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-03-009', '1.12', 191.65, 191.65, NULL, '2026-04-17'),
  ('INS-2026-03-009', '1.13', NULL, NULL, NULL, NULL),
  ('INS-2026-03-010', '1.1', 3059.34, 3059.34, NULL, '2026-04-16'),
  ('INS-2026-03-010', '1.2', 844.03, 844.03, NULL, '2026-04-19'),
  ('INS-2026-03-010', '1.3', 1521.31, 1521.31, NULL, '2026-04-18'),
  ('INS-2026-03-010', '1.4', 207.91, 207.91, NULL, '2026-04-17'),
  ('INS-2026-03-010', '1.5', 120.01, 120.01, NULL, '2026-04-18'),
  ('INS-2026-03-010', '1.6', 659.24, 659.24, NULL, '2026-04-16'),
  ('INS-2026-03-010', '1.7', 1504.41, 1504.41, NULL, '2026-04-19'),
  ('INS-2026-03-010', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-03-010', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-03-010', '1.10', NULL, NULL, NULL, NULL),
  ('INS-2026-03-010', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-03-010', '1.12', 101.42, 101.42, NULL, '2026-04-16'),
  ('INS-2026-03-010', '1.13', 67.61, 67.61, NULL, '2026-04-17'),
  ('INS-2026-03-011', '1.1', 0.00, 0.00, NULL, '2026-04-16'),
  ('INS-2026-03-011', '1.2', 724.42, 724.42, NULL, '2026-04-14'),
  ('INS-2026-03-011', '1.3', 1119.82, 1119.82, NULL, '2026-04-17'),
  ('INS-2026-03-011', '1.4', 153.04, 153.04, NULL, '2026-04-16'),
  ('INS-2026-03-011', '1.5', 88.34, 88.34, NULL, '2026-04-16'),
  ('INS-2026-03-011', '1.6', 485.26, 485.26, NULL, '2026-04-16'),
  ('INS-2026-03-011', '1.7', 1107.38, 1119.98, 12.60, '2026-04-23'),
  ('INS-2026-03-011', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-03-011', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-03-011', '1.10', NULL, NULL, NULL, NULL),
  ('INS-2026-03-011', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-03-011', '1.12', 74.65, 74.65, NULL, '2026-04-14'),
  ('INS-2026-03-011', '1.13', NULL, NULL, NULL, NULL),
  ('INS-2026-03-012', '1.1', 2801.19, 2801.19, NULL, '2026-04-11'),
  ('INS-2026-03-012', '1.2', 959.13, 959.13, NULL, '2026-04-11'),
  ('INS-2026-03-012', '1.3', 2219.67, 2219.67, NULL, '2026-04-13'),
  ('INS-2026-03-012', '1.4', 303.35, 303.35, NULL, '2026-04-13'),
  ('INS-2026-03-012', '1.5', 175.11, 175.11, NULL, '2026-04-13'),
  ('INS-2026-03-012', '1.6', 961.86, 961.86, NULL, '2026-04-13'),
  ('INS-2026-03-012', '1.7', 2195.01, 2195.01, NULL, '2026-04-12'),
  ('INS-2026-03-012', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-03-012', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-03-012', '1.10', NULL, NULL, NULL, NULL),
  ('INS-2026-03-012', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-03-012', '1.12', 147.98, 147.98, NULL, '2026-04-12'),
  ('INS-2026-03-012', '1.13', NULL, NULL, NULL, NULL),
  ('INS-2026-03-013', '1.1', 2479.15, 2479.15, NULL, '2026-04-12'),
  ('INS-2026-03-013', '1.2', 1344.48, 1344.48, NULL, '2026-04-10'),
  ('INS-2026-03-013', '1.3', 2312.80, 2312.80, NULL, '2026-04-12'),
  ('INS-2026-03-013', '1.4', 316.08, 316.08, NULL, '2026-04-13'),
  ('INS-2026-03-013', '1.5', 182.45, 182.45, NULL, '2026-04-10'),
  ('INS-2026-03-013', '1.6', 1002.21, 1002.21, NULL, '2026-04-12'),
  ('INS-2026-03-013', '1.7', 2287.10, 2287.10, NULL, '2026-04-13'),
  ('INS-2026-03-013', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-03-013', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-03-013', '1.10', 145.00, 145.00, NULL, '2026-04-13'),
  ('INS-2026-03-013', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-03-013', '1.12', 154.19, 154.19, NULL, '2026-04-13'),
  ('INS-2026-03-013', '1.13', NULL, NULL, NULL, NULL),
  ('INS-2026-03-014', '1.1', 3905.44, 3905.44, NULL, '2026-04-12'),
  ('INS-2026-03-014', '1.2', 1390.33, 1390.33, NULL, '2026-04-15'),
  ('INS-2026-03-014', '1.3', 1713.00, 1713.00, NULL, '2026-04-12'),
  ('INS-2026-03-014', '1.4', 234.11, 234.11, NULL, '2026-04-14'),
  ('INS-2026-03-014', '1.5', 135.14, 135.14, NULL, '2026-04-12'),
  ('INS-2026-03-014', '1.6', 742.30, 742.30, NULL, '2026-04-14');
INSERT INTO DECLARA (Num_inspeccion, Cod_obligacion, Monto_declarado, Monto_pagado, Mora, Fecha_pago) VALUES
  ('INS-2026-03-014', '1.7', 1693.97, 1693.97, NULL, '2026-04-14'),
  ('INS-2026-03-014', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-03-014', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-03-014', '1.10', NULL, NULL, NULL, NULL),
  ('INS-2026-03-014', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-03-014', '1.12', 114.20, 114.20, NULL, '2026-04-13'),
  ('INS-2026-03-014', '1.13', NULL, NULL, NULL, NULL),
  ('INS-2026-03-015', '1.1', 6586.88, 6586.88, NULL, '2026-04-16'),
  ('INS-2026-03-015', '1.2', 2502.36, 2502.36, NULL, '2026-04-16'),
  ('INS-2026-03-015', '1.3', 2946.24, 2946.24, NULL, '2026-04-14'),
  ('INS-2026-03-015', '1.4', 402.65, 402.65, NULL, '2026-04-16'),
  ('INS-2026-03-015', '1.5', 232.43, 232.43, NULL, '2026-04-14'),
  ('INS-2026-03-015', '1.6', 1276.70, 1276.70, NULL, '2026-04-15'),
  ('INS-2026-03-015', '1.7', 2913.50, 2913.50, NULL, '2026-04-17'),
  ('INS-2026-03-015', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-03-015', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-03-015', '1.10', NULL, NULL, NULL, NULL),
  ('INS-2026-03-015', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-03-015', '1.12', 196.42, 196.42, NULL, '2026-04-15'),
  ('INS-2026-03-015', '1.13', 130.94, 130.94, NULL, '2026-04-15'),
  ('INS-2026-04-001', '1.1', 1455.14, 1455.14, NULL, '2026-05-14'),
  ('INS-2026-04-001', '1.2', 631.67, 631.67, NULL, '2026-05-15'),
  ('INS-2026-04-001', '1.3', 1297.51, 1297.51, NULL, '2026-05-16'),
  ('INS-2026-04-001', '1.4', 177.33, 177.33, NULL, '2026-05-14'),
  ('INS-2026-04-001', '1.5', 102.36, 102.36, NULL, '2026-05-15'),
  ('INS-2026-04-001', '1.6', 562.25, 562.25, NULL, '2026-05-16'),
  ('INS-2026-04-001', '1.7', 1283.09, 1283.09, NULL, '2026-05-16'),
  ('INS-2026-04-001', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-04-001', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-04-001', '1.10', NULL, NULL, NULL, NULL),
  ('INS-2026-04-001', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-04-001', '1.12', 86.50, 86.50, NULL, '2026-05-16'),
  ('INS-2026-04-001', '1.13', NULL, NULL, NULL, NULL),
  ('INS-2026-04-002', '1.1', 5911.42, 5911.42, NULL, '2026-05-18'),
  ('INS-2026-04-002', '1.2', 2275.95, 2275.95, NULL, '2026-05-17'),
  ('INS-2026-04-002', '1.3', 2764.83, 2764.83, NULL, '2026-05-19'),
  ('INS-2026-04-002', '1.4', 377.86, 377.86, NULL, '2026-05-19'),
  ('INS-2026-04-002', '1.5', 218.11, 218.11, NULL, '2026-05-18'),
  ('INS-2026-04-002', '1.6', 1198.09, 1198.09, NULL, '2026-05-17'),
  ('INS-2026-04-002', '1.7', 2734.11, 2734.11, NULL, '2026-05-19'),
  ('INS-2026-04-002', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-04-002', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-04-002', '1.10', 262.50, 262.50, NULL, '2026-05-17'),
  ('INS-2026-04-002', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-04-002', '1.12', 184.32, 184.32, NULL, '2026-05-16'),
  ('INS-2026-04-002', '1.13', NULL, NULL, NULL, NULL),
  ('INS-2026-04-003', '1.1', 1601.79, 1601.79, NULL, '2026-05-18'),
  ('INS-2026-04-003', '1.2', 844.84, 844.84, NULL, '2026-05-16'),
  ('INS-2026-04-003', '1.3', 1528.57, 1528.57, NULL, '2026-05-16'),
  ('INS-2026-04-003', '1.4', 208.90, 208.90, NULL, '2026-05-17'),
  ('INS-2026-04-003', '1.5', 120.59, 120.59, NULL, '2026-05-17'),
  ('INS-2026-04-003', '1.6', 662.38, 662.38, NULL, '2026-05-16'),
  ('INS-2026-04-003', '1.7', 1511.59, 1511.59, NULL, '2026-05-17'),
  ('INS-2026-04-003', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-04-003', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-04-003', '1.10', NULL, NULL, NULL, NULL),
  ('INS-2026-04-003', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-04-003', '1.12', 101.90, 101.90, NULL, '2026-05-17'),
  ('INS-2026-04-003', '1.13', 67.94, 67.94, NULL, '2026-05-16'),
  ('INS-2026-04-004', '1.1', 2170.97, 2170.97, NULL, '2026-05-13'),
  ('INS-2026-04-004', '1.2', 958.26, 958.26, NULL, '2026-05-12'),
  ('INS-2026-04-004', '1.3', 2211.84, 2211.84, NULL, '2026-05-10'),
  ('INS-2026-04-004', '1.4', 302.29, 302.29, NULL, '2026-05-12'),
  ('INS-2026-04-004', '1.5', 174.49, 174.49, NULL, '2026-05-11'),
  ('INS-2026-04-004', '1.6', 958.47, 958.47, NULL, '2026-05-13'),
  ('INS-2026-04-004', '1.7', 2187.27, 2187.27, NULL, '2026-05-11'),
  ('INS-2026-04-004', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-04-004', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-04-004', '1.10', NULL, NULL, NULL, NULL),
  ('INS-2026-04-004', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-04-004', '1.12', 147.46, 147.46, NULL, '2026-05-11'),
  ('INS-2026-04-004', '1.13', NULL, NULL, NULL, NULL),
  ('INS-2026-04-005', '1.1', 1165.93, 1165.93, NULL, '2026-05-16'),
  ('INS-2026-04-005', '1.2', 520.45, 520.45, NULL, '2026-05-18'),
  ('INS-2026-04-005', '1.3', 1646.52, 1646.52, NULL, '2026-05-18'),
  ('INS-2026-04-005', '1.4', 225.02, 225.02, NULL, '2026-05-16'),
  ('INS-2026-04-005', '1.5', 129.89, 129.89, NULL, '2026-05-18'),
  ('INS-2026-04-005', '1.6', 713.49, 713.49, NULL, '2026-05-16'),
  ('INS-2026-04-005', '1.7', 1628.22, 1628.22, NULL, '2026-05-17'),
  ('INS-2026-04-005', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-04-005', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-04-005', '1.10', NULL, NULL, NULL, NULL),
  ('INS-2026-04-005', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-04-005', '1.12', 109.77, 109.77, NULL, '2026-05-16'),
  ('INS-2026-04-005', '1.13', NULL, NULL, NULL, NULL),
  ('INS-2026-04-006', '1.1', 0.00, 0.00, NULL, '2026-05-14'),
  ('INS-2026-04-006', '1.2', 641.71, 641.71, NULL, '2026-05-15'),
  ('INS-2026-04-006', '1.3', 1894.10, 1894.10, NULL, '2026-05-17'),
  ('INS-2026-04-006', '1.4', 258.86, 258.86, NULL, '2026-05-16'),
  ('INS-2026-04-006', '1.5', 149.42, 149.42, NULL, '2026-05-16'),
  ('INS-2026-04-006', '1.6', 820.78, 820.78, NULL, '2026-05-14'),
  ('INS-2026-04-006', '1.7', 1873.06, 1873.06, NULL, '2026-05-16'),
  ('INS-2026-04-006', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-04-006', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-04-006', '1.10', NULL, NULL, NULL, NULL),
  ('INS-2026-04-006', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-04-006', '1.12', 126.27, 126.27, NULL, '2026-05-17'),
  ('INS-2026-04-006', '1.13', NULL, NULL, NULL, NULL),
  ('INS-2026-04-007', '1.1', 3478.11, 3478.11, NULL, '2026-05-15'),
  ('INS-2026-04-007', '1.2', 1235.58, 1235.58, NULL, '2026-05-15');
INSERT INTO DECLARA (Num_inspeccion, Cod_obligacion, Monto_declarado, Monto_pagado, Mora, Fecha_pago) VALUES
  ('INS-2026-04-007', '1.3', 1670.26, 1670.26, NULL, '2026-05-14'),
  ('INS-2026-04-007', '1.4', 228.27, 228.27, NULL, '2026-05-12'),
  ('INS-2026-04-007', '1.5', 131.77, 131.77, NULL, '2026-05-14'),
  ('INS-2026-04-007', '1.6', 723.78, 723.78, NULL, '2026-05-12'),
  ('INS-2026-04-007', '1.7', 1651.71, 1651.71, NULL, '2026-05-12'),
  ('INS-2026-04-007', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-04-007', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-04-007', '1.10', NULL, NULL, NULL, NULL),
  ('INS-2026-04-007', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-04-007', '1.12', 111.35, 111.35, NULL, '2026-05-15'),
  ('INS-2026-04-007', '1.13', NULL, NULL, NULL, NULL),
  ('INS-2026-04-008', '1.1', 0.00, 0.00, NULL, '2026-05-16'),
  ('INS-2026-04-008', '1.2', 726.94, 726.94, NULL, '2026-05-16'),
  ('INS-2026-04-008', '1.3', 1142.48, 1142.48, NULL, '2026-05-14'),
  ('INS-2026-04-008', '1.4', 156.14, 156.14, NULL, '2026-05-17'),
  ('INS-2026-04-008', '1.5', 90.13, 90.13, NULL, '2026-05-14'),
  ('INS-2026-04-008', '1.6', 495.08, 495.08, NULL, '2026-05-14'),
  ('INS-2026-04-008', '1.7', 1129.79, 1129.79, NULL, '2026-05-15'),
  ('INS-2026-04-008', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-04-008', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-04-008', '1.10', NULL, NULL, NULL, NULL),
  ('INS-2026-04-008', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-04-008', '1.12', 76.17, 76.17, NULL, '2026-05-16'),
  ('INS-2026-04-008', '1.13', NULL, NULL, NULL, NULL),
  ('INS-2026-04-009', '1.1', 2910.15, 2910.15, NULL, '2026-05-11'),
  ('INS-2026-04-009', '1.2', 1670.36, 1670.36, NULL, '2026-05-14'),
  ('INS-2026-04-009', '1.3', 2883.25, 2883.25, NULL, '2026-05-11'),
  ('INS-2026-04-009', '1.4', 394.04, 394.04, NULL, '2026-05-14'),
  ('INS-2026-04-009', '1.5', 227.46, 227.46, NULL, '2026-05-13'),
  ('INS-2026-04-009', '1.6', 1249.41, 1249.41, NULL, '2026-05-14'),
  ('INS-2026-04-009', '1.7', 2851.22, 2851.22, NULL, '2026-05-11'),
  ('INS-2026-04-009', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-04-009', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-04-009', '1.10', NULL, NULL, NULL, NULL),
  ('INS-2026-04-009', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-04-009', '1.12', 192.22, 192.22, NULL, '2026-05-11'),
  ('INS-2026-04-009', '1.13', NULL, NULL, NULL, NULL),
  ('INS-2026-04-010', '1.1', 2099.78, 2099.78, NULL, '2026-05-17'),
  ('INS-2026-04-010', '1.2', 991.40, 991.40, NULL, '2026-05-19'),
  ('INS-2026-04-010', '1.3', 1835.06, 1835.06, NULL, '2026-05-16'),
  ('INS-2026-04-010', '1.4', 250.79, 250.79, NULL, '2026-05-16'),
  ('INS-2026-04-010', '1.5', 144.77, 144.77, NULL, '2026-05-16'),
  ('INS-2026-04-010', '1.6', 795.19, 795.19, NULL, '2026-05-18'),
  ('INS-2026-04-010', '1.7', 1814.67, 1814.67, NULL, '2026-05-19'),
  ('INS-2026-04-010', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-04-010', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-04-010', '1.10', NULL, NULL, NULL, NULL),
  ('INS-2026-04-010', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-04-010', '1.12', 122.34, 122.34, NULL, '2026-05-18'),
  ('INS-2026-04-010', '1.13', 81.56, 81.56, NULL, '2026-05-17'),
  ('INS-2026-04-011', '1.1', 5488.82, 5488.82, NULL, '2026-05-16'),
  ('INS-2026-04-011', '1.2', 2497.07, 2497.07, NULL, '2026-05-16'),
  ('INS-2026-04-011', '1.3', 2898.59, 2898.59, NULL, '2026-05-15'),
  ('INS-2026-04-011', '1.4', 396.14, 396.14, NULL, '2026-05-17'),
  ('INS-2026-04-011', '1.5', 228.67, 228.67, NULL, '2026-05-14'),
  ('INS-2026-04-011', '1.6', 1256.06, 1256.06, NULL, '2026-05-15'),
  ('INS-2026-04-011', '1.7', 2866.39, 2866.39, NULL, '2026-05-17'),
  ('INS-2026-04-011', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-04-011', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-04-011', '1.10', NULL, NULL, NULL, NULL),
  ('INS-2026-04-011', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-04-011', '1.12', 193.24, 193.24, NULL, '2026-05-17'),
  ('INS-2026-04-011', '1.13', 128.83, 128.83, NULL, '2026-05-15'),
  ('INS-2026-04-012', '1.1', 8226.07, 8226.07, NULL, '2026-05-13'),
  ('INS-2026-04-012', '1.2', 2120.49, 2120.49, NULL, '2026-05-10'),
  ('INS-2026-04-012', '1.3', 3053.12, 3053.12, NULL, '2026-05-13'),
  ('INS-2026-04-012', '1.4', 417.26, 417.26, NULL, '2026-05-12'),
  ('INS-2026-04-012', '1.5', 240.86, 240.86, NULL, '2026-05-13'),
  ('INS-2026-04-012', '1.6', 1323.02, 1323.02, NULL, '2026-05-10'),
  ('INS-2026-04-012', '1.7', 3019.20, 3019.20, NULL, '2026-05-11'),
  ('INS-2026-04-012', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-04-012', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-04-012', '1.10', 237.50, 237.50, NULL, '2026-05-13'),
  ('INS-2026-04-012', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-04-012', '1.12', 203.54, 203.54, NULL, '2026-05-12'),
  ('INS-2026-04-012', '1.13', NULL, NULL, NULL, NULL),
  ('INS-2026-04-013', '1.1', 2968.21, 2968.21, NULL, '2026-05-14'),
  ('INS-2026-04-013', '1.2', 1387.11, 1387.11, NULL, '2026-05-14'),
  ('INS-2026-04-013', '1.3', 1684.02, 1684.02, NULL, '2026-05-15'),
  ('INS-2026-04-013', '1.4', 230.15, 230.15, NULL, '2026-05-12'),
  ('INS-2026-04-013', '1.5', 132.85, 132.85, NULL, '2026-05-13'),
  ('INS-2026-04-013', '1.6', 729.74, 729.74, NULL, '2026-05-13'),
  ('INS-2026-04-013', '1.7', 1665.31, 1665.31, NULL, '2026-05-15'),
  ('INS-2026-04-013', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-04-013', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-04-013', '1.10', NULL, NULL, NULL, NULL),
  ('INS-2026-04-013', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-04-013', '1.12', 112.27, 112.27, NULL, '2026-05-12'),
  ('INS-2026-04-013', '1.13', NULL, NULL, NULL, NULL),
  ('INS-2026-04-014', '1.1', 5625.67, 5625.67, NULL, '2026-05-13'),
  ('INS-2026-04-014', '1.2', 2002.66, 2002.66, NULL, '2026-05-13'),
  ('INS-2026-04-014', '1.3', 3173.90, 3173.90, NULL, '2026-05-13'),
  ('INS-2026-04-014', '1.4', 433.77, 433.77, NULL, '2026-05-10'),
  ('INS-2026-04-014', '1.5', 250.39, 250.39, NULL, '2026-05-11'),
  ('INS-2026-04-014', '1.6', 1375.36, 1375.36, NULL, '2026-05-10'),
  ('INS-2026-04-014', '1.7', 3138.64, 3138.64, NULL, '2026-05-10'),
  ('INS-2026-04-014', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-04-014', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-04-014', '1.10', NULL, NULL, NULL, NULL),
  ('INS-2026-04-014', '1.11', 264.49, 264.49, NULL, '2026-05-10');
INSERT INTO DECLARA (Num_inspeccion, Cod_obligacion, Monto_declarado, Monto_pagado, Mora, Fecha_pago) VALUES
  ('INS-2026-04-014', '1.12', 211.59, 211.59, NULL, '2026-05-11'),
  ('INS-2026-04-014', '1.13', NULL, NULL, NULL, NULL),
  ('INS-2026-04-015', '1.1', 2257.58, 2257.58, NULL, '2026-05-12'),
  ('INS-2026-04-015', '1.2', 1345.04, 1345.04, NULL, '2026-05-10'),
  ('INS-2026-04-015', '1.3', 2317.89, 2317.89, NULL, '2026-05-10'),
  ('INS-2026-04-015', '1.4', 316.78, 316.78, NULL, '2026-05-12'),
  ('INS-2026-04-015', '1.5', 182.86, 182.86, NULL, '2026-05-11'),
  ('INS-2026-04-015', '1.6', 1004.42, 1004.42, NULL, '2026-05-11'),
  ('INS-2026-04-015', '1.7', 2292.14, 2292.14, NULL, '2026-05-11'),
  ('INS-2026-04-015', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-04-015', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-04-015', '1.10', 145.00, 145.00, NULL, '2026-05-12'),
  ('INS-2026-04-015', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-04-015', '1.12', 154.53, 154.53, NULL, '2026-05-10'),
  ('INS-2026-04-015', '1.13', NULL, NULL, NULL, NULL),
  ('INS-2026-05-001', '1.1', 0.00, 0.00, NULL, '2026-06-14'),
  ('INS-2026-05-001', '1.2', 727.24, 727.24, NULL, '2026-06-15'),
  ('INS-2026-05-001', '1.3', 1145.18, 1145.18, NULL, '2026-06-15'),
  ('INS-2026-05-001', '1.4', 156.51, 156.51, NULL, '2026-06-14'),
  ('INS-2026-05-001', '1.5', 90.34, 90.34, NULL, '2026-06-16'),
  ('INS-2026-05-001', '1.6', 496.25, 496.25, NULL, '2026-06-17'),
  ('INS-2026-05-001', '1.7', 1132.46, 1132.46, NULL, '2026-06-14'),
  ('INS-2026-05-001', '1.8', 7380.08, 7380.08, NULL, '2026-05-10'),
  ('INS-2026-05-001', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-05-001', '1.10', NULL, NULL, NULL, NULL),
  ('INS-2026-05-001', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-05-001', '1.12', 76.35, 76.35, NULL, '2026-06-17'),
  ('INS-2026-05-001', '1.13', NULL, NULL, NULL, NULL),
  ('INS-2026-05-002', '1.1', 7349.60, 7349.60, NULL, '2026-06-12'),
  ('INS-2026-05-002', '1.2', 2127.67, 2127.67, NULL, '2026-06-13'),
  ('INS-2026-05-002', '1.3', 3117.77, 3117.77, NULL, '2026-06-10'),
  ('INS-2026-05-002', '1.4', 426.09, 426.09, NULL, '2026-06-12'),
  ('INS-2026-05-002', '1.5', 245.96, 245.96, NULL, '2026-06-12'),
  ('INS-2026-05-002', '1.6', 1351.03, 1351.03, NULL, '2026-06-11'),
  ('INS-2026-05-002', '1.7', 3083.12, 3083.12, NULL, '2026-06-12'),
  ('INS-2026-05-002', '1.8', 20092.26, 20092.26, NULL, '2026-05-10'),
  ('INS-2026-05-002', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-05-002', '1.10', 237.50, 237.50, NULL, '2026-06-10'),
  ('INS-2026-05-002', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-05-002', '1.12', 207.85, 207.85, NULL, '2026-06-12'),
  ('INS-2026-05-002', '1.13', NULL, NULL, NULL, NULL),
  ('INS-2026-05-003', '1.1', 3049.49, 3049.49, NULL, '2026-06-14'),
  ('INS-2026-05-003', '1.2', 1382.03, 1382.03, NULL, '2026-06-14'),
  ('INS-2026-05-003', '1.3', 1638.29, 1638.29, NULL, '2026-06-14'),
  ('INS-2026-05-003', '1.4', 223.90, 223.90, NULL, '2026-06-12'),
  ('INS-2026-05-003', '1.5', 129.24, 129.24, NULL, '2026-06-14'),
  ('INS-2026-05-003', '1.6', 709.93, 709.93, NULL, '2026-06-13'),
  ('INS-2026-05-003', '1.7', 1620.09, 1620.09, NULL, '2026-06-13'),
  ('INS-2026-05-003', '1.8', 10557.89, 10557.89, NULL, '2026-05-11'),
  ('INS-2026-05-003', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-05-003', '1.10', NULL, NULL, NULL, NULL),
  ('INS-2026-05-003', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-05-003', '1.12', 109.22, 109.22, NULL, '2026-06-15'),
  ('INS-2026-05-003', '1.13', NULL, NULL, NULL, NULL),
  ('INS-2026-05-004', '1.1', 1579.87, 1579.87, NULL, '2026-06-17'),
  ('INS-2026-05-004', '1.2', 629.75, 629.75, NULL, '2026-06-15'),
  ('INS-2026-05-004', '1.3', 1280.27, 1280.27, NULL, '2026-06-17'),
  ('INS-2026-05-004', '1.4', 174.97, 174.97, NULL, '2026-06-16'),
  ('INS-2026-05-004', '1.5', 101.00, 101.00, NULL, '2026-06-16'),
  ('INS-2026-05-004', '1.6', 554.79, 554.79, NULL, '2026-06-15'),
  ('INS-2026-05-004', '1.7', 1266.05, 1266.05, NULL, '2026-06-15'),
  ('INS-2026-05-004', '1.8', 8250.65, 8250.65, NULL, '2026-05-12'),
  ('INS-2026-05-004', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-05-004', '1.10', NULL, NULL, NULL, NULL),
  ('INS-2026-05-004', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-05-004', '1.12', 85.35, 85.35, NULL, '2026-06-16'),
  ('INS-2026-05-004', '1.13', NULL, NULL, NULL, NULL),
  ('INS-2026-05-005', '1.1', 0.00, 0.00, NULL, '2026-06-17'),
  ('INS-2026-05-005', '1.2', 642.98, 642.98, NULL, '2026-06-17'),
  ('INS-2026-05-005', '1.3', 1905.58, 1905.58, NULL, '2026-06-17'),
  ('INS-2026-05-005', '1.4', 260.43, 260.43, NULL, '2026-06-17'),
  ('INS-2026-05-005', '1.5', 150.33, 150.33, NULL, '2026-06-15'),
  ('INS-2026-05-005', '1.6', 825.75, 825.75, NULL, '2026-06-15'),
  ('INS-2026-05-005', '1.7', 1884.41, 1884.41, NULL, '2026-06-14'),
  ('INS-2026-05-005', '1.8', 12280.40, 12280.40, NULL, '2026-05-13'),
  ('INS-2026-05-005', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-05-005', '1.10', NULL, NULL, NULL, NULL),
  ('INS-2026-05-005', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-05-005', '1.12', 127.04, 127.04, NULL, '2026-06-16'),
  ('INS-2026-05-005', '1.13', NULL, NULL, NULL, NULL),
  ('INS-2026-05-006', '1.1', 2796.30, 2796.30, NULL, '2026-06-13'),
  ('INS-2026-05-006', '1.2', 1341.69, 1341.69, NULL, '2026-06-12'),
  ('INS-2026-05-006', '1.3', 2287.70, 2287.70, NULL, '2026-06-10'),
  ('INS-2026-05-006', '1.4', 312.65, 312.65, NULL, '2026-06-13'),
  ('INS-2026-05-006', '1.5', 180.47, 180.47, NULL, '2026-06-10'),
  ('INS-2026-05-006', '1.6', 991.33, 991.33, NULL, '2026-06-11'),
  ('INS-2026-05-006', '1.7', 2262.28, 2262.28, NULL, '2026-06-12'),
  ('INS-2026-05-006', '1.8', 14742.92, 14742.92, NULL, '2026-05-12'),
  ('INS-2026-05-006', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-05-006', '1.10', 145.00, 145.00, NULL, '2026-06-11'),
  ('INS-2026-05-006', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-05-006', '1.12', 152.51, 152.51, NULL, '2026-06-10'),
  ('INS-2026-05-006', '1.13', NULL, NULL, NULL, NULL),
  ('INS-2026-05-007', '1.1', 3466.84, 3466.84, NULL, '2026-06-13'),
  ('INS-2026-05-007', '1.2', 1235.49, 1235.49, NULL, '2026-06-12'),
  ('INS-2026-05-007', '1.3', 1669.42, 1669.42, NULL, '2026-06-15'),
  ('INS-2026-05-007', '1.4', 228.15, 228.15, NULL, '2026-06-13'),
  ('INS-2026-05-007', '1.5', 131.70, 131.70, NULL, '2026-06-12'),
  ('INS-2026-05-007', '1.6', 723.42, 723.42, NULL, '2026-06-14'),
  ('INS-2026-05-007', '1.7', 1650.87, 1650.87, NULL, '2026-06-15');
INSERT INTO DECLARA (Num_inspeccion, Cod_obligacion, Monto_declarado, Monto_pagado, Mora, Fecha_pago) VALUES
  ('INS-2026-05-007', '1.8', 10758.49, 10758.49, NULL, '2026-05-12'),
  ('INS-2026-05-007', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-05-007', '1.10', NULL, NULL, NULL, NULL),
  ('INS-2026-05-007', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-05-007', '1.12', 111.29, 111.29, NULL, '2026-06-12'),
  ('INS-2026-05-007', '1.13', NULL, NULL, NULL, NULL),
  ('INS-2026-05-008', '1.1', 9227.29, 9227.29, NULL, '2026-06-15'),
  ('INS-2026-05-008', '1.2', 2511.32, 2511.32, NULL, '2026-06-17'),
  ('INS-2026-05-008', '1.3', 3026.85, 3026.85, NULL, '2026-06-14'),
  ('INS-2026-05-008', '1.4', 413.67, 413.67, NULL, '2026-06-16'),
  ('INS-2026-05-008', '1.5', 238.78, 238.78, NULL, '2026-06-15'),
  ('INS-2026-05-008', '1.6', 1311.63, 1311.63, NULL, '2026-06-17'),
  ('INS-2026-05-008', '1.7', 2993.22, 2993.22, NULL, '2026-06-17'),
  ('INS-2026-05-008', '1.8', 19506.36, 19506.36, NULL, '2026-05-09'),
  ('INS-2026-05-008', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-05-008', '1.10', NULL, NULL, NULL, NULL),
  ('INS-2026-05-008', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-05-008', '1.12', 201.79, 201.79, NULL, '2026-06-15'),
  ('INS-2026-05-008', '1.13', 134.53, 134.53, NULL, '2026-06-16'),
  ('INS-2026-05-009', '1.1', 3587.39, 3587.39, NULL, '2026-06-11'),
  ('INS-2026-05-009', '1.2', 2012.84, 2012.84, NULL, '2026-06-11'),
  ('INS-2026-05-009', '1.3', 3265.59, 3265.59, NULL, '2026-06-12'),
  ('INS-2026-05-009', '1.4', 446.30, 446.30, NULL, '2026-06-12'),
  ('INS-2026-05-009', '1.5', 257.62, 257.62, NULL, '2026-06-11'),
  ('INS-2026-05-009', '1.6', 1415.09, 1415.09, NULL, '2026-06-11'),
  ('INS-2026-05-009', '1.7', 3229.30, 3229.30, NULL, '2026-06-12'),
  ('INS-2026-05-009', '1.8', 21044.89, 21044.89, NULL, '2026-05-11'),
  ('INS-2026-05-009', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-05-009', '1.10', NULL, NULL, NULL, NULL),
  ('INS-2026-05-009', '1.11', 272.13, 272.13, NULL, '2026-06-10'),
  ('INS-2026-05-009', '1.12', 217.71, 217.71, NULL, '2026-06-13'),
  ('INS-2026-05-009', '1.13', NULL, NULL, NULL, NULL),
  ('INS-2026-05-010', '1.1', 1466.45, 1466.45, NULL, '2026-06-17'),
  ('INS-2026-05-010', '1.2', 841.82, 841.82, NULL, '2026-06-19'),
  ('INS-2026-05-010', '1.3', 1501.35, 1501.35, NULL, '2026-06-16'),
  ('INS-2026-05-010', '1.4', 205.18, 205.18, NULL, '2026-06-17'),
  ('INS-2026-05-010', '1.5', 118.44, 118.44, NULL, '2026-06-17'),
  ('INS-2026-05-010', '1.6', 650.59, 650.59, NULL, '2026-06-18'),
  ('INS-2026-05-010', '1.7', 1484.67, 1484.67, NULL, '2026-06-17'),
  ('INS-2026-05-010', '1.8', 9675.37, 9675.37, NULL, '2026-05-12'),
  ('INS-2026-05-010', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-05-010', '1.10', NULL, NULL, NULL, NULL),
  ('INS-2026-05-010', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-05-010', '1.12', 100.09, 100.09, NULL, '2026-06-16'),
  ('INS-2026-05-010', '1.13', 66.73, 66.73, NULL, '2026-06-19'),
  ('INS-2026-05-011', '1.1', 2779.27, 2779.27, NULL, '2026-06-14'),
  ('INS-2026-05-011', '1.2', 1099.76, 1099.76, NULL, '2026-06-14'),
  ('INS-2026-05-011', '1.3', 2472.88, 2472.88, NULL, '2026-06-12'),
  ('INS-2026-05-011', '1.4', 337.96, 337.96, NULL, '2026-06-12'),
  ('INS-2026-05-011', '1.5', 195.08, 195.08, NULL, '2026-06-14'),
  ('INS-2026-05-011', '1.6', 1071.58, 1071.58, NULL, '2026-06-14'),
  ('INS-2026-05-011', '1.7', 2445.40, 2445.40, NULL, '2026-06-13'),
  ('INS-2026-05-011', '1.8', 15936.33, 15936.33, NULL, '2026-05-11'),
  ('INS-2026-05-011', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-05-011', '1.10', NULL, NULL, NULL, NULL),
  ('INS-2026-05-011', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-05-011', '1.12', 164.86, 164.86, NULL, '2026-06-12'),
  ('INS-2026-05-011', '1.13', NULL, NULL, NULL, NULL),
  ('INS-2026-05-012', '1.1', 2989.84, 2989.84, NULL, '2026-06-11'),
  ('INS-2026-05-012', '1.2', 952.84, 952.84, NULL, '2026-06-13'),
  ('INS-2026-05-012', '1.3', 2163.06, 2163.06, NULL, '2026-06-12'),
  ('INS-2026-05-012', '1.4', 295.62, 295.62, NULL, '2026-06-13'),
  ('INS-2026-05-012', '1.5', 170.64, 170.64, NULL, '2026-06-12'),
  ('INS-2026-05-012', '1.6', 937.33, 944.68, 7.35, '2026-06-25'),
  ('INS-2026-05-012', '1.7', 2139.03, 2139.03, NULL, '2026-06-11'),
  ('INS-2026-05-012', '1.8', 13939.75, 13939.75, NULL, '2026-05-11'),
  ('INS-2026-05-012', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-05-012', '1.10', NULL, NULL, NULL, NULL),
  ('INS-2026-05-012', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-05-012', '1.12', 144.20, 144.20, NULL, '2026-06-11'),
  ('INS-2026-05-012', '1.13', NULL, NULL, NULL, NULL),
  ('INS-2026-05-013', '1.1', 1248.16, 1248.16, NULL, '2026-06-17'),
  ('INS-2026-05-013', '1.2', 527.80, 527.80, NULL, '2026-06-16'),
  ('INS-2026-05-013', '1.3', 1712.66, 1712.66, NULL, '2026-06-18'),
  ('INS-2026-05-013', '1.4', 234.06, 234.06, NULL, '2026-06-15'),
  ('INS-2026-05-013', '1.5', 135.11, 135.11, NULL, '2026-06-16'),
  ('INS-2026-05-013', '1.6', 742.15, 742.15, NULL, '2026-06-18'),
  ('INS-2026-05-013', '1.7', 1693.63, 1693.63, NULL, '2026-06-16'),
  ('INS-2026-05-013', '1.8', 11037.14, 11037.14, NULL, '2026-05-11'),
  ('INS-2026-05-013', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-05-013', '1.10', NULL, NULL, NULL, NULL),
  ('INS-2026-05-013', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-05-013', '1.12', 114.18, 114.18, NULL, '2026-06-15'),
  ('INS-2026-05-013', '1.13', NULL, NULL, NULL, NULL),
  ('INS-2026-05-014', '1.1', 1915.78, 1915.78, NULL, '2026-06-16'),
  ('INS-2026-05-014', '1.2', 992.37, 992.37, NULL, '2026-06-16'),
  ('INS-2026-05-014', '1.3', 1843.83, 1843.83, NULL, '2026-06-18'),
  ('INS-2026-05-014', '1.4', 251.99, 251.99, NULL, '2026-06-17'),
  ('INS-2026-05-014', '1.5', 145.46, 145.46, NULL, '2026-06-16'),
  ('INS-2026-05-014', '1.6', 798.99, 798.99, NULL, '2026-06-16'),
  ('INS-2026-05-014', '1.7', 1823.34, 1823.34, NULL, '2026-06-18'),
  ('INS-2026-05-014', '1.8', 11882.44, 11882.44, NULL, '2026-05-08'),
  ('INS-2026-05-014', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-05-014', '1.10', NULL, NULL, NULL, NULL),
  ('INS-2026-05-014', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-05-014', '1.12', 122.92, 122.92, NULL, '2026-06-18'),
  ('INS-2026-05-014', '1.13', 81.95, 81.95, NULL, '2026-06-16'),
  ('INS-2026-05-015', '1.1', 0.00, 0.00, NULL, '2026-06-14'),
  ('INS-2026-05-015', '1.2', 635.64, 635.64, NULL, '2026-06-17'),
  ('INS-2026-05-015', '1.3', 1839.47, 1839.47, NULL, '2026-06-14');
INSERT INTO DECLARA (Num_inspeccion, Cod_obligacion, Monto_declarado, Monto_pagado, Mora, Fecha_pago) VALUES
  ('INS-2026-05-015', '1.4', 251.39, 251.39, NULL, '2026-06-14'),
  ('INS-2026-05-015', '1.5', 145.11, 145.11, NULL, '2026-06-16'),
  ('INS-2026-05-015', '1.6', 797.10, 797.10, NULL, '2026-06-15'),
  ('INS-2026-05-015', '1.7', 1819.03, 1819.03, NULL, '2026-06-15'),
  ('INS-2026-05-015', '1.8', 11854.36, 11854.36, NULL, '2026-05-10'),
  ('INS-2026-05-015', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-05-015', '1.10', NULL, NULL, NULL, NULL),
  ('INS-2026-05-015', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-05-015', '1.12', 122.63, 122.63, NULL, '2026-06-17'),
  ('INS-2026-05-015', '1.13', NULL, NULL, NULL, NULL),
  ('INS-2026-05-016', '1.1', 5864.65, 5864.65, NULL, '2026-06-14'),
  ('INS-2026-05-016', '1.2', 1663.15, 1663.15, NULL, '2026-06-11'),
  ('INS-2026-05-016', '1.3', 2818.35, 2818.35, NULL, '2026-06-11'),
  ('INS-2026-05-016', '1.4', 385.17, 385.17, NULL, '2026-06-12'),
  ('INS-2026-05-016', '1.5', 222.34, 222.34, NULL, '2026-06-11'),
  ('INS-2026-05-016', '1.6', 1221.29, 1221.29, NULL, '2026-06-11'),
  ('INS-2026-05-016', '1.7', 2787.04, 2787.04, NULL, '2026-06-13'),
  ('INS-2026-05-016', '1.8', 18162.71, 18162.71, NULL, '2026-05-10'),
  ('INS-2026-05-016', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-05-016', '1.10', NULL, NULL, NULL, NULL),
  ('INS-2026-05-016', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-05-016', '1.12', 187.89, 187.89, NULL, '2026-06-14'),
  ('INS-2026-05-016', '1.13', NULL, NULL, NULL, NULL),
  ('INS-2026-05-017', '1.1', 7087.66, 7087.66, NULL, '2026-06-17'),
  ('INS-2026-05-017', '1.2', 2277.26, 2277.26, NULL, '2026-06-18'),
  ('INS-2026-05-017', '1.3', 2776.55, 2776.55, NULL, '2026-06-18'),
  ('INS-2026-05-017', '1.4', 379.46, 379.46, NULL, '2026-06-19'),
  ('INS-2026-05-017', '1.5', 219.04, 219.04, NULL, '2026-06-18'),
  ('INS-2026-05-017', '1.6', 1203.17, 1203.17, NULL, '2026-06-17'),
  ('INS-2026-05-017', '1.7', 2745.70, 2745.70, NULL, '2026-06-17'),
  ('INS-2026-05-017', '1.8', 17893.31, 17893.31, NULL, '2026-05-08'),
  ('INS-2026-05-017', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-05-017', '1.10', 262.50, 262.50, NULL, '2026-06-18'),
  ('INS-2026-05-017', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-05-017', '1.12', 185.10, 185.10, NULL, '2026-06-19'),
  ('INS-2026-05-017', '1.13', NULL, NULL, NULL, NULL),
  ('INS-2026-06-001', '1.1', 0.00, 0.00, NULL, '2026-07-16'),
  ('INS-2026-06-001', '1.2', 724.88, 724.88, NULL, '2026-07-17'),
  ('INS-2026-06-001', '1.3', 1123.94, 1123.94, NULL, '2026-07-15'),
  ('INS-2026-06-001', '1.4', 153.61, 153.61, NULL, '2026-07-14'),
  ('INS-2026-06-001', '1.5', 88.67, 88.67, NULL, '2026-07-14'),
  ('INS-2026-06-001', '1.6', 487.04, 487.04, NULL, '2026-07-14'),
  ('INS-2026-06-001', '1.7', 1111.45, 1111.45, NULL, '2026-07-14'),
  ('INS-2026-06-001', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-06-001', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-06-001', '1.10', NULL, NULL, NULL, NULL),
  ('INS-2026-06-001', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-06-001', '1.12', 74.93, 74.93, NULL, '2026-07-17'),
  ('INS-2026-06-001', '1.13', NULL, NULL, NULL, NULL),
  ('INS-2026-06-002', '1.1', 3189.87, 3189.87, NULL, '2026-07-15'),
  ('INS-2026-06-002', '1.2', 1386.76, 1386.76, NULL, '2026-07-13'),
  ('INS-2026-06-002', '1.3', 1680.82, 1680.82, NULL, '2026-07-12'),
  ('INS-2026-06-002', '1.4', 229.71, 229.71, NULL, '2026-07-13'),
  ('INS-2026-06-002', '1.5', 132.60, 132.60, NULL, '2026-07-15'),
  ('INS-2026-06-002', '1.6', 728.36, 728.36, NULL, '2026-07-12'),
  ('INS-2026-06-002', '1.7', 1662.15, 1662.15, NULL, '2026-07-13'),
  ('INS-2026-06-002', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-06-002', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-06-002', '1.10', NULL, NULL, NULL, NULL),
  ('INS-2026-06-002', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-06-002', '1.12', 112.05, 112.05, NULL, '2026-07-14'),
  ('INS-2026-06-002', '1.13', NULL, NULL, NULL, NULL),
  ('INS-2026-06-003', '1.1', 6442.10, 6442.10, NULL, '2026-07-13'),
  ('INS-2026-06-003', '1.2', 2129.31, 2129.31, NULL, '2026-07-11'),
  ('INS-2026-06-003', '1.3', 3132.57, 3132.57, NULL, '2026-07-11'),
  ('INS-2026-06-003', '1.4', 428.12, 428.12, NULL, '2026-07-10'),
  ('INS-2026-06-003', '1.5', 247.12, 247.12, NULL, '2026-07-12'),
  ('INS-2026-06-003', '1.6', 1357.45, 1357.45, NULL, '2026-07-11'),
  ('INS-2026-06-003', '1.7', 3097.76, 3097.76, NULL, '2026-07-13'),
  ('INS-2026-06-003', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-06-003', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-06-003', '1.10', 237.50, 237.50, NULL, '2026-07-13'),
  ('INS-2026-06-003', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-06-003', '1.12', 208.84, 208.84, NULL, '2026-07-10'),
  ('INS-2026-06-003', '1.13', NULL, NULL, NULL, NULL),
  ('INS-2026-06-004', '1.1', 2733.30, 2733.30, NULL, '2026-07-13'),
  ('INS-2026-06-004', '1.2', 1094.46, 1094.46, NULL, '2026-07-11'),
  ('INS-2026-06-004', '1.3', 2425.12, 2425.12, NULL, '2026-07-12'),
  ('INS-2026-06-004', '1.4', 331.43, 331.43, NULL, '2026-07-13'),
  ('INS-2026-06-004', '1.5', 191.31, 191.31, NULL, '2026-07-13'),
  ('INS-2026-06-004', '1.6', 1050.89, 1050.89, NULL, '2026-07-11'),
  ('INS-2026-06-004', '1.7', 2398.17, 2398.17, NULL, '2026-07-13'),
  ('INS-2026-06-004', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-06-004', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-06-004', '1.10', NULL, NULL, NULL, NULL),
  ('INS-2026-06-004', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-06-004', '1.12', 161.67, 161.67, NULL, '2026-07-11'),
  ('INS-2026-06-004', '1.13', NULL, NULL, NULL, NULL),
  ('INS-2026-06-005', '1.1', 7789.67, 7789.67, NULL, '2026-07-14'),
  ('INS-2026-06-005', '1.2', 2507.16, 2507.16, NULL, '2026-07-15'),
  ('INS-2026-06-005', '1.3', 2989.47, 2989.47, NULL, '2026-07-17'),
  ('INS-2026-06-005', '1.4', 408.56, 408.56, NULL, '2026-07-14'),
  ('INS-2026-06-005', '1.5', 235.84, 235.84, NULL, '2026-07-14'),
  ('INS-2026-06-005', '1.6', 1295.44, 1295.44, NULL, '2026-07-16'),
  ('INS-2026-06-005', '1.7', 2956.25, 2956.25, NULL, '2026-07-16'),
  ('INS-2026-06-005', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-06-005', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-06-005', '1.10', NULL, NULL, NULL, NULL),
  ('INS-2026-06-005', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-06-005', '1.12', 199.30, 199.30, NULL, '2026-07-15');
INSERT INTO DECLARA (Num_inspeccion, Cod_obligacion, Monto_declarado, Monto_pagado, Mora, Fecha_pago) VALUES
  ('INS-2026-06-005', '1.13', 132.87, 132.87, NULL, '2026-07-14'),
  ('INS-2026-06-006', '1.1', 2735.56, 2735.56, NULL, '2026-07-13'),
  ('INS-2026-06-006', '1.2', 1664.09, 1664.09, NULL, '2026-07-12'),
  ('INS-2026-06-006', '1.3', 2826.77, 2826.77, NULL, '2026-07-13'),
  ('INS-2026-06-006', '1.4', 386.33, 386.33, NULL, '2026-07-14'),
  ('INS-2026-06-006', '1.5', 223.00, 223.00, NULL, '2026-07-12'),
  ('INS-2026-06-006', '1.6', 1224.94, 1224.94, NULL, '2026-07-12'),
  ('INS-2026-06-006', '1.7', 2795.37, 2795.37, NULL, '2026-07-13'),
  ('INS-2026-06-006', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-06-006', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-06-006', '1.10', NULL, NULL, NULL, NULL),
  ('INS-2026-06-006', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-06-006', '1.12', 188.45, 188.45, NULL, '2026-07-13'),
  ('INS-2026-06-006', '1.13', NULL, NULL, NULL, NULL),
  ('INS-2026-06-007', '1.1', 2402.45, 2402.45, NULL, '2026-07-19'),
  ('INS-2026-06-007', '1.2', 990.43, 990.43, NULL, '2026-07-19'),
  ('INS-2026-06-007', '1.3', 1826.36, 1826.36, NULL, '2026-07-16'),
  ('INS-2026-06-007', '1.4', 249.60, 249.60, NULL, '2026-07-19'),
  ('INS-2026-06-007', '1.5', 144.08, 144.08, NULL, '2026-07-17'),
  ('INS-2026-06-007', '1.6', 791.42, 791.42, NULL, '2026-07-19'),
  ('INS-2026-06-007', '1.7', 1806.07, 1806.07, NULL, '2026-07-19'),
  ('INS-2026-06-007', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-06-007', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-06-007', '1.10', NULL, NULL, NULL, NULL),
  ('INS-2026-06-007', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-06-007', '1.12', 121.76, 121.76, NULL, '2026-07-18'),
  ('INS-2026-06-007', '1.13', 81.17, 81.17, NULL, '2026-07-19'),
  ('INS-2026-06-008', '1.1', 6483.21, 6483.21, NULL, '2026-07-17'),
  ('INS-2026-06-008', '1.2', 2276.03, 2276.03, NULL, '2026-07-18'),
  ('INS-2026-06-008', '1.3', 2765.55, 2765.55, NULL, '2026-07-18'),
  ('INS-2026-06-008', '1.4', 377.96, 377.96, NULL, '2026-07-16'),
  ('INS-2026-06-008', '1.5', 218.17, 218.17, NULL, '2026-07-17'),
  ('INS-2026-06-008', '1.6', 1198.41, 1198.41, NULL, '2026-07-18'),
  ('INS-2026-06-008', '1.7', 2734.83, 2734.83, NULL, '2026-07-17'),
  ('INS-2026-06-008', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-06-008', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-06-008', '1.10', 262.50, 262.50, NULL, '2026-07-16'),
  ('INS-2026-06-008', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-06-008', '1.12', 184.37, 184.37, NULL, '2026-07-19'),
  ('INS-2026-06-008', '1.13', NULL, NULL, NULL, NULL),
  ('INS-2026-06-009', '1.1', 3140.63, 3140.63, NULL, '2026-07-13'),
  ('INS-2026-06-009', '1.2', 955.45, 955.45, NULL, '2026-07-12'),
  ('INS-2026-06-009', '1.3', 2186.51, 2186.51, NULL, '2026-07-10'),
  ('INS-2026-06-009', '1.4', 298.82, 298.82, NULL, '2026-07-12'),
  ('INS-2026-06-009', '1.5', 172.49, 172.49, NULL, '2026-07-11'),
  ('INS-2026-06-009', '1.6', 947.49, 947.49, NULL, '2026-07-13'),
  ('INS-2026-06-009', '1.7', 2162.22, 2162.22, NULL, '2026-07-11'),
  ('INS-2026-06-009', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-06-009', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-06-009', '1.10', NULL, NULL, NULL, NULL),
  ('INS-2026-06-009', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-06-009', '1.12', 145.77, 145.77, NULL, '2026-07-10'),
  ('INS-2026-06-009', '1.13', NULL, NULL, NULL, NULL),
  ('INS-2026-06-010', '1.1', 0.00, 0.00, NULL, '2026-07-17'),
  ('INS-2026-06-010', '1.2', 642.78, 642.78, NULL, '2026-07-14'),
  ('INS-2026-06-010', '1.3', 1903.75, 1903.75, NULL, '2026-07-15'),
  ('INS-2026-06-010', '1.4', 260.18, 260.18, NULL, '2026-07-17'),
  ('INS-2026-06-010', '1.5', 150.18, 150.18, NULL, '2026-07-16'),
  ('INS-2026-06-010', '1.6', 824.96, 824.96, NULL, '2026-07-14'),
  ('INS-2026-06-010', '1.7', 1882.59, 1882.59, NULL, '2026-07-17'),
  ('INS-2026-06-010', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-06-010', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-06-010', '1.10', NULL, NULL, NULL, NULL),
  ('INS-2026-06-010', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-06-010', '1.12', 126.92, 126.92, NULL, '2026-07-14'),
  ('INS-2026-06-010', '1.13', NULL, NULL, NULL, NULL),
  ('INS-2026-06-011', '1.1', 770.73, 770.73, NULL, '2026-07-17'),
  ('INS-2026-06-011', '1.2', 524.07, 524.07, NULL, '2026-07-17'),
  ('INS-2026-06-011', '1.3', 1679.16, 1679.16, NULL, '2026-07-17'),
  ('INS-2026-06-011', '1.4', 229.49, 229.49, NULL, '2026-07-17'),
  ('INS-2026-06-011', '1.5', 132.47, 132.47, NULL, '2026-07-17'),
  ('INS-2026-06-011', '1.6', 727.64, 727.64, NULL, '2026-07-17'),
  ('INS-2026-06-011', '1.7', 1660.50, 1660.50, NULL, '2026-07-15'),
  ('INS-2026-06-011', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-06-011', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-06-011', '1.10', NULL, NULL, NULL, NULL),
  ('INS-2026-06-011', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-06-011', '1.12', 111.94, 111.94, NULL, '2026-07-18'),
  ('INS-2026-06-011', '1.13', NULL, NULL, NULL, NULL),
  ('INS-2026-06-012', '1.1', 2912.03, 2912.03, NULL, '2026-07-16'),
  ('INS-2026-06-012', '1.2', 845.74, 845.74, NULL, '2026-07-18'),
  ('INS-2026-06-012', '1.3', 1536.62, 1536.62, NULL, '2026-07-17'),
  ('INS-2026-06-012', '1.4', 210.00, 210.00, NULL, '2026-07-17'),
  ('INS-2026-06-012', '1.5', 121.22, 121.22, NULL, '2026-07-18'),
  ('INS-2026-06-012', '1.6', 665.87, 665.87, NULL, '2026-07-17'),
  ('INS-2026-06-012', '1.7', 1519.54, 1519.54, NULL, '2026-07-16'),
  ('INS-2026-06-012', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-06-012', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-06-012', '1.10', NULL, NULL, NULL, NULL),
  ('INS-2026-06-012', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-06-012', '1.12', 102.44, 102.44, NULL, '2026-07-17'),
  ('INS-2026-06-012', '1.13', 68.29, 68.29, NULL, '2026-07-19'),
  ('INS-2026-06-013', '1.1', 3504.82, 3504.82, NULL, '2026-07-14'),
  ('INS-2026-06-013', '1.2', 1236.73, 1236.73, NULL, '2026-07-12'),
  ('INS-2026-06-013', '1.3', 1680.58, 1680.58, NULL, '2026-07-13'),
  ('INS-2026-06-013', '1.4', 229.68, 229.68, NULL, '2026-07-14'),
  ('INS-2026-06-013', '1.5', 132.58, 132.58, NULL, '2026-07-14'),
  ('INS-2026-06-013', '1.6', 728.25, 728.25, NULL, '2026-07-15'),
  ('INS-2026-06-013', '1.7', 1661.91, 1661.91, NULL, '2026-07-15'),
  ('INS-2026-06-013', '1.8', NULL, NULL, NULL, NULL);
INSERT INTO DECLARA (Num_inspeccion, Cod_obligacion, Monto_declarado, Monto_pagado, Mora, Fecha_pago) VALUES
  ('INS-2026-06-013', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-06-013', '1.10', NULL, NULL, NULL, NULL),
  ('INS-2026-06-013', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-06-013', '1.12', 112.04, 112.04, NULL, '2026-07-12'),
  ('INS-2026-06-013', '1.13', NULL, NULL, NULL, NULL),
  ('INS-2026-06-014', '1.1', 6197.73, 6197.73, NULL, '2026-07-13'),
  ('INS-2026-06-014', '1.2', 2011.71, 2011.71, NULL, '2026-07-11'),
  ('INS-2026-06-014', '1.3', 3255.40, 3255.40, NULL, '2026-07-13'),
  ('INS-2026-06-014', '1.4', 444.90, 444.90, NULL, '2026-07-13'),
  ('INS-2026-06-014', '1.5', 256.81, 256.81, NULL, '2026-07-10'),
  ('INS-2026-06-014', '1.6', 1410.67, 1410.67, NULL, '2026-07-10'),
  ('INS-2026-06-014', '1.7', 3219.23, 3219.23, NULL, '2026-07-10'),
  ('INS-2026-06-014', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-06-014', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-06-014', '1.10', NULL, NULL, NULL, NULL),
  ('INS-2026-06-014', '1.11', 271.28, 271.28, NULL, '2026-07-11'),
  ('INS-2026-06-014', '1.12', 217.03, 217.03, NULL, '2026-07-12'),
  ('INS-2026-06-014', '1.13', NULL, NULL, NULL, NULL),
  ('INS-2026-06-015', '1.1', 1982.89, 1982.89, NULL, '2026-07-16'),
  ('INS-2026-06-015', '1.2', 633.38, 633.38, NULL, '2026-07-15'),
  ('INS-2026-06-015', '1.3', 1312.93, 1312.93, NULL, '2026-07-15'),
  ('INS-2026-06-015', '1.4', 179.43, 179.43, NULL, '2026-07-14'),
  ('INS-2026-06-015', '1.5', 103.58, 103.58, NULL, '2026-07-16'),
  ('INS-2026-06-015', '1.6', 568.93, 568.93, NULL, '2026-07-15'),
  ('INS-2026-06-015', '1.7', 1298.34, 1298.34, NULL, '2026-07-16'),
  ('INS-2026-06-015', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-06-015', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-06-015', '1.10', NULL, NULL, NULL, NULL),
  ('INS-2026-06-015', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-06-015', '1.12', 87.53, 87.53, NULL, '2026-07-16'),
  ('INS-2026-06-015', '1.13', NULL, NULL, NULL, NULL),
  ('INS-2026-06-016', '1.1', 2452.88, 2452.88, NULL, '2026-07-10'),
  ('INS-2026-06-016', '1.2', 1348.63, 1348.63, NULL, '2026-07-12'),
  ('INS-2026-06-016', '1.3', 2350.20, 2350.20, NULL, '2026-07-11'),
  ('INS-2026-06-016', '1.4', 321.19, 321.19, NULL, '2026-07-12'),
  ('INS-2026-06-016', '1.5', 185.40, 185.40, NULL, '2026-07-12'),
  ('INS-2026-06-016', '1.6', 1018.42, 1018.42, NULL, '2026-07-12'),
  ('INS-2026-06-016', '1.7', 2324.09, 2324.09, NULL, '2026-07-13'),
  ('INS-2026-06-016', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-06-016', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-06-016', '1.10', 145.00, 145.00, NULL, '2026-07-13'),
  ('INS-2026-06-016', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-06-016', '1.12', 156.68, 156.68, NULL, '2026-07-11'),
  ('INS-2026-06-016', '1.13', NULL, NULL, NULL, NULL),
  ('INS-2026-07-001', '1.1', 6924.60, 6924.60, NULL, '2026-08-14'),
  ('INS-2026-07-001', '1.2', 2510.18, 2510.18, NULL, '2026-08-14'),
  ('INS-2026-07-001', '1.3', 3016.60, 3016.60, NULL, '2026-08-16'),
  ('INS-2026-07-001', '1.4', 412.27, 412.27, NULL, '2026-08-17'),
  ('INS-2026-07-001', '1.5', 237.98, 237.98, NULL, '2026-08-16'),
  ('INS-2026-07-001', '1.6', 1307.19, 1307.19, NULL, '2026-08-17'),
  ('INS-2026-07-001', '1.7', 2983.08, 2983.08, NULL, '2026-08-16'),
  ('INS-2026-07-001', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-07-001', '1.9', 33517.76, 33517.76, NULL, '2026-07-08'),
  ('INS-2026-07-001', '1.10', NULL, NULL, NULL, NULL),
  ('INS-2026-07-001', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-07-001', '1.12', 201.11, 201.11, NULL, '2026-08-14'),
  ('INS-2026-07-001', '1.13', 134.07, 134.07, NULL, '2026-08-14'),
  ('INS-2026-07-002', '1.1', 3597.05, 3597.05, NULL, '2026-08-14'),
  ('INS-2026-07-002', '1.2', 1087.03, 1087.03, NULL, '2026-08-14'),
  ('INS-2026-07-002', '1.3', 2358.31, 2358.31, NULL, '2026-08-13'),
  ('INS-2026-07-002', '1.4', 322.30, 322.30, NULL, '2026-08-12'),
  ('INS-2026-07-002', '1.5', 186.04, 186.04, NULL, '2026-08-11'),
  ('INS-2026-07-002', '1.6', 1021.93, 1021.93, NULL, '2026-08-12'),
  ('INS-2026-07-002', '1.7', 2332.10, 2332.10, NULL, '2026-08-14'),
  ('INS-2026-07-002', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-07-002', '1.9', 26203.41, 26203.41, NULL, '2026-07-09'),
  ('INS-2026-07-002', '1.10', NULL, NULL, NULL, NULL),
  ('INS-2026-07-002', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-07-002', '1.12', 157.22, 157.22, NULL, '2026-08-11'),
  ('INS-2026-07-002', '1.13', NULL, NULL, NULL, NULL),
  ('INS-2026-07-003', '1.1', 0.00, 0.00, NULL, '2026-08-16'),
  ('INS-2026-07-003', '1.2', 727.15, 727.15, NULL, '2026-08-14'),
  ('INS-2026-07-003', '1.3', 1144.36, 1144.36, NULL, '2026-08-14'),
  ('INS-2026-07-003', '1.4', 156.40, 156.40, NULL, '2026-08-14'),
  ('INS-2026-07-003', '1.5', 90.28, 90.28, NULL, '2026-08-16'),
  ('INS-2026-07-003', '1.6', 495.89, 495.89, NULL, '2026-08-16'),
  ('INS-2026-07-003', '1.7', 1131.65, 1131.65, NULL, '2026-08-17'),
  ('INS-2026-07-003', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-07-003', '1.9', 12715.16, 12715.16, NULL, '2026-07-10'),
  ('INS-2026-07-003', '1.10', NULL, NULL, NULL, NULL),
  ('INS-2026-07-003', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-07-003', '1.12', 76.29, 76.29, NULL, '2026-08-14'),
  ('INS-2026-07-003', '1.13', NULL, NULL, NULL, NULL),
  ('INS-2026-07-004', '1.1', 4935.37, 4935.37, NULL, '2026-08-16'),
  ('INS-2026-07-004', '1.2', 2289.92, 2289.92, NULL, '2026-08-19'),
  ('INS-2026-07-004', '1.3', 2890.52, 2890.52, NULL, '2026-08-17'),
  ('INS-2026-07-004', '1.4', 395.04, 395.04, NULL, '2026-08-18'),
  ('INS-2026-07-004', '1.5', 228.03, 228.03, NULL, '2026-08-19'),
  ('INS-2026-07-004', '1.6', 1252.56, 1252.56, NULL, '2026-08-18'),
  ('INS-2026-07-004', '1.7', 2858.41, 2858.41, NULL, '2026-08-18'),
  ('INS-2026-07-004', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-07-004', '1.9', 32116.94, 32116.94, NULL, '2026-07-15'),
  ('INS-2026-07-004', '1.10', 262.50, 262.50, NULL, '2026-08-17'),
  ('INS-2026-07-004', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-07-004', '1.12', 192.70, 192.70, NULL, '2026-08-17'),
  ('INS-2026-07-004', '1.13', NULL, NULL, NULL, NULL),
  ('INS-2026-07-005', '1.1', 3320.55, 3320.55, NULL, '2026-08-11'),
  ('INS-2026-07-005', '1.2', 2014.33, 2014.33, NULL, '2026-08-13'),
  ('INS-2026-07-005', '1.3', 3279.00, 3279.00, NULL, '2026-08-12'),
  ('INS-2026-07-005', '1.4', 448.13, 448.13, NULL, '2026-08-13');
INSERT INTO DECLARA (Num_inspeccion, Cod_obligacion, Monto_declarado, Monto_pagado, Mora, Fecha_pago) VALUES
  ('INS-2026-07-005', '1.5', 258.68, 258.68, NULL, '2026-08-13'),
  ('INS-2026-07-005', '1.6', 1420.90, 1420.90, NULL, '2026-08-12'),
  ('INS-2026-07-005', '1.7', 3242.57, 3242.57, NULL, '2026-08-13'),
  ('INS-2026-07-005', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-07-005', '1.9', 36433.36, 36433.36, NULL, '2026-07-15'),
  ('INS-2026-07-005', '1.10', NULL, NULL, NULL, NULL),
  ('INS-2026-07-005', '1.11', 273.25, 273.25, NULL, '2026-08-13'),
  ('INS-2026-07-005', '1.12', 218.60, 218.60, NULL, '2026-08-13'),
  ('INS-2026-07-005', '1.13', NULL, NULL, NULL, NULL),
  ('INS-2026-07-006', '1.1', 2142.35, 2142.35, NULL, '2026-08-17'),
  ('INS-2026-07-006', '1.2', 842.57, 842.57, NULL, '2026-08-17'),
  ('INS-2026-07-006', '1.3', 1508.17, 1508.17, NULL, '2026-08-19'),
  ('INS-2026-07-006', '1.4', 206.12, 206.12, NULL, '2026-08-18'),
  ('INS-2026-07-006', '1.5', 118.98, 118.98, NULL, '2026-08-19'),
  ('INS-2026-07-006', '1.6', 653.54, 653.54, NULL, '2026-08-18'),
  ('INS-2026-07-006', '1.7', 1491.42, 1491.42, NULL, '2026-08-18'),
  ('INS-2026-07-006', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-07-006', '1.9', 16757.49, 16757.49, NULL, '2026-07-12'),
  ('INS-2026-07-006', '1.10', NULL, NULL, NULL, NULL),
  ('INS-2026-07-006', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-07-006', '1.12', 100.54, 100.54, NULL, '2026-08-16'),
  ('INS-2026-07-006', '1.13', 67.03, 67.03, NULL, '2026-08-17'),
  ('INS-2026-07-007', '1.1', 7716.38, 7716.38, NULL, '2026-08-12'),
  ('INS-2026-07-007', '1.2', 2119.93, 2119.93, NULL, '2026-08-10'),
  ('INS-2026-07-007', '1.3', 3048.13, 3138.13, NULL, '2026-08-11'),
  ('INS-2026-07-007', '1.4', 416.58, 416.58, NULL, '2026-08-11'),
  ('INS-2026-07-007', '1.5', 240.46, 240.46, NULL, '2026-08-12'),
  ('INS-2026-07-007', '1.6', 1320.86, 1320.86, NULL, '2026-08-10'),
  ('INS-2026-07-007', '1.7', 3014.27, 3014.27, NULL, '2026-08-10'),
  ('INS-2026-07-007', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-07-007', '1.9', 33868.16, 33868.16, NULL, '2026-07-12'),
  ('INS-2026-07-007', '1.10', 237.50, 237.50, NULL, '2026-08-13'),
  ('INS-2026-07-007', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-07-007', '1.12', 203.21, 203.21, NULL, '2026-08-12'),
  ('INS-2026-07-007', '1.13', NULL, NULL, NULL, NULL),
  ('INS-2026-07-008', '1.1', 5329.05, 5329.05, NULL, '2026-08-14'),
  ('INS-2026-07-008', '1.2', 1385.39, 1385.39, NULL, '2026-08-15'),
  ('INS-2026-07-008', '1.3', 1668.48, 1668.48, NULL, '2026-08-15'),
  ('INS-2026-07-008', '1.4', 228.03, 228.03, NULL, '2026-08-13'),
  ('INS-2026-07-008', '1.5', 131.62, 131.62, NULL, '2026-08-15'),
  ('INS-2026-07-008', '1.6', 723.01, 723.01, NULL, '2026-08-15'),
  ('INS-2026-07-008', '1.7', 1649.95, 1649.95, NULL, '2026-08-14'),
  ('INS-2026-07-008', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-07-008', '1.9', 18538.72, 18538.72, NULL, '2026-07-10'),
  ('INS-2026-07-008', '1.10', NULL, NULL, NULL, NULL),
  ('INS-2026-07-008', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-07-008', '1.12', 111.23, 111.23, NULL, '2026-08-12'),
  ('INS-2026-07-008', '1.13', NULL, NULL, NULL, NULL),
  ('INS-2026-07-009', '1.1', 5472.54, 5472.54, NULL, '2026-08-13'),
  ('INS-2026-07-009', '1.2', 1673.02, 1673.02, NULL, '2026-08-12'),
  ('INS-2026-07-009', '1.3', 2907.21, 2907.21, NULL, '2026-08-11'),
  ('INS-2026-07-009', '1.4', 397.32, 397.32, NULL, '2026-08-11'),
  ('INS-2026-07-009', '1.5', 229.35, 229.35, NULL, '2026-08-11'),
  ('INS-2026-07-009', '1.6', 1259.79, 1259.79, NULL, '2026-08-11'),
  ('INS-2026-07-009', '1.7', 2874.91, 2874.91, NULL, '2026-08-14'),
  ('INS-2026-07-009', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-07-009', '1.9', 32302.35, 32302.35, NULL, '2026-07-09'),
  ('INS-2026-07-009', '1.10', NULL, NULL, NULL, NULL),
  ('INS-2026-07-009', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-07-009', '1.12', 193.81, 193.81, NULL, '2026-08-13'),
  ('INS-2026-07-009', '1.13', NULL, NULL, NULL, NULL),
  ('INS-2026-07-010', '1.1', 1408.97, 1408.97, NULL, '2026-08-14'),
  ('INS-2026-07-010', '1.2', 628.10, 628.10, NULL, '2026-08-14'),
  ('INS-2026-07-010', '1.3', 1265.40, 1265.40, NULL, '2026-08-14'),
  ('INS-2026-07-010', '1.4', 172.94, 172.94, NULL, '2026-08-17'),
  ('INS-2026-07-010', '1.5', 99.83, 99.83, NULL, '2026-08-16'),
  ('INS-2026-07-010', '1.6', 548.34, 548.34, NULL, '2026-08-17'),
  ('INS-2026-07-010', '1.7', 1251.34, 1251.34, NULL, '2026-08-14'),
  ('INS-2026-07-010', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-07-010', '1.9', 14060.05, 11951.04, NULL, '2026-07-15'),
  ('INS-2026-07-010', '1.10', NULL, NULL, NULL, NULL),
  ('INS-2026-07-010', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-07-010', '1.12', 84.36, 84.36, NULL, '2026-08-16'),
  ('INS-2026-07-010', '1.13', NULL, NULL, NULL, NULL),
  ('INS-2026-07-011', '1.1', 0.00, 0.00, NULL, '2026-08-17'),
  ('INS-2026-07-011', '1.2', 644.63, 644.63, NULL, '2026-08-16'),
  ('INS-2026-07-011', '1.3', 1920.44, 1920.44, NULL, '2026-08-15'),
  ('INS-2026-07-011', '1.4', 262.46, 262.46, NULL, '2026-08-16'),
  ('INS-2026-07-011', '1.5', 151.50, 151.50, NULL, '2026-08-16'),
  ('INS-2026-07-011', '1.6', 832.19, 832.19, NULL, '2026-08-16'),
  ('INS-2026-07-011', '1.7', 1899.10, 1899.10, NULL, '2026-08-15'),
  ('INS-2026-07-011', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-07-011', '1.9', 21338.17, 21338.17, NULL, '2026-07-11'),
  ('INS-2026-07-011', '1.10', NULL, NULL, NULL, NULL),
  ('INS-2026-07-011', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-07-011', '1.12', 128.03, 128.03, NULL, '2026-08-14'),
  ('INS-2026-07-011', '1.13', NULL, NULL, NULL, NULL),
  ('INS-2026-07-012', '1.1', 2127.39, 2127.39, NULL, '2026-08-14'),
  ('INS-2026-07-012', '1.2', 1240.60, 1240.60, NULL, '2026-08-13'),
  ('INS-2026-07-012', '1.3', 1715.38, 1715.38, NULL, '2026-08-15'),
  ('INS-2026-07-012', '1.4', 234.44, 234.44, NULL, '2026-08-12'),
  ('INS-2026-07-012', '1.5', 135.32, 135.32, NULL, '2026-08-13'),
  ('INS-2026-07-012', '1.6', 743.33, 743.33, NULL, '2026-08-14'),
  ('INS-2026-07-012', '1.7', 1696.32, 1696.32, NULL, '2026-08-14'),
  ('INS-2026-07-012', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-07-012', '1.9', 19059.82, 19059.82, NULL, '2026-07-13'),
  ('INS-2026-07-012', '1.10', NULL, NULL, NULL, NULL),
  ('INS-2026-07-012', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-07-012', '1.12', 114.36, 119.76, 5.40, '2026-08-22'),
  ('INS-2026-07-012', '1.13', NULL, NULL, NULL, NULL);
INSERT INTO DECLARA (Num_inspeccion, Cod_obligacion, Monto_declarado, Monto_pagado, Mora, Fecha_pago) VALUES
  ('INS-2026-07-013', '1.1', 2062.12, 2062.12, NULL, '2026-08-10'),
  ('INS-2026-07-013', '1.2', 956.24, 956.24, NULL, '2026-08-10'),
  ('INS-2026-07-013', '1.3', 2193.64, 2193.64, NULL, '2026-08-13'),
  ('INS-2026-07-013', '1.4', 299.80, 299.80, NULL, '2026-08-10'),
  ('INS-2026-07-013', '1.5', 173.05, 173.05, NULL, '2026-08-11'),
  ('INS-2026-07-013', '1.6', 950.58, 950.58, NULL, '2026-08-11'),
  ('INS-2026-07-013', '1.7', 2169.27, 2169.27, NULL, '2026-08-13'),
  ('INS-2026-07-013', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-07-013', '1.9', 24373.80, 24373.80, NULL, '2026-07-11'),
  ('INS-2026-07-013', '1.10', NULL, NULL, NULL, NULL),
  ('INS-2026-07-013', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-07-013', '1.12', 146.24, 146.24, NULL, '2026-08-13'),
  ('INS-2026-07-013', '1.13', NULL, NULL, NULL, NULL),
  ('INS-2026-07-014', '1.1', 2472.77, 2472.77, NULL, '2026-08-18'),
  ('INS-2026-07-014', '1.2', 994.32, 994.32, NULL, '2026-08-17'),
  ('INS-2026-07-014', '1.3', 1861.37, 1861.37, NULL, '2026-08-16'),
  ('INS-2026-07-014', '1.4', 254.39, 254.39, NULL, '2026-08-18'),
  ('INS-2026-07-014', '1.5', 146.84, 146.84, NULL, '2026-08-16'),
  ('INS-2026-07-014', '1.6', 806.59, 806.59, NULL, '2026-08-18'),
  ('INS-2026-07-014', '1.7', 1840.69, 1858.90, 18.21, '2026-08-29'),
  ('INS-2026-07-014', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-07-014', '1.9', 20681.86, 20681.86, NULL, '2026-07-09'),
  ('INS-2026-07-014', '1.10', NULL, NULL, NULL, NULL),
  ('INS-2026-07-014', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-07-014', '1.12', 124.09, 124.09, NULL, '2026-08-19'),
  ('INS-2026-07-014', '1.13', 82.73, 82.73, NULL, '2026-08-19'),
  ('INS-2026-07-015', '1.1', 1465.12, 1465.12, NULL, '2026-08-17'),
  ('INS-2026-07-015', '1.2', 527.83, 527.83, NULL, '2026-08-17'),
  ('INS-2026-07-015', '1.3', 1713.00, 1713.00, NULL, '2026-08-18'),
  ('INS-2026-07-015', '1.4', 234.11, 234.11, NULL, '2026-08-16'),
  ('INS-2026-07-015', '1.5', 135.14, 135.14, NULL, '2026-08-17'),
  ('INS-2026-07-015', '1.6', 742.30, 742.30, NULL, '2026-08-16'),
  ('INS-2026-07-015', '1.7', 1693.96, 1693.96, NULL, '2026-08-15'),
  ('INS-2026-07-015', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-07-015', '1.9', 19033.29, 19033.29, NULL, '2026-07-09'),
  ('INS-2026-07-015', '1.10', NULL, NULL, NULL, NULL),
  ('INS-2026-07-015', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-07-015', '1.12', 114.20, 114.20, NULL, '2026-08-18'),
  ('INS-2026-07-015', '1.13', NULL, NULL, NULL, NULL),
  ('INS-2026-07-016', '1.1', 3902.37, 3902.37, NULL, '2026-08-10'),
  ('INS-2026-07-016', '1.2', 1338.27, 1338.27, NULL, '2026-08-10'),
  ('INS-2026-07-016', '1.3', 2256.95, 2270.95, 14.00, '2026-08-23'),
  ('INS-2026-07-016', '1.4', 308.45, 308.45, NULL, '2026-08-13'),
  ('INS-2026-07-016', '1.5', 178.05, 178.05, NULL, '2026-08-11'),
  ('INS-2026-07-016', '1.6', 978.01, 978.01, NULL, '2026-08-11'),
  ('INS-2026-07-016', '1.7', 2231.87, 2231.87, NULL, '2026-08-13'),
  ('INS-2026-07-016', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-07-016', '1.9', 25077.18, 25077.18, NULL, '2026-07-08'),
  ('INS-2026-07-016', '1.10', 145.00, 145.00, NULL, '2026-08-11'),
  ('INS-2026-07-016', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-07-016', '1.12', 150.46, 150.46, NULL, '2026-08-12'),
  ('INS-2026-07-016', '1.13', NULL, NULL, NULL, NULL),
  ('INS-2026-08-001', '1.1', 0.00, 0.00, NULL, '2026-09-15'),
  ('INS-2026-08-001', '1.2', 644.08, 644.08, NULL, '2026-09-17'),
  ('INS-2026-08-001', '1.3', 1915.43, 1915.43, NULL, '2026-09-14'),
  ('INS-2026-08-001', '1.4', 261.78, 261.78, NULL, '2026-09-15'),
  ('INS-2026-08-001', '1.5', 151.11, 151.11, NULL, '2026-09-17'),
  ('INS-2026-08-001', '1.6', 830.02, 830.02, NULL, '2026-09-16'),
  ('INS-2026-08-001', '1.7', 1894.15, 1894.15, NULL, '2026-09-15'),
  ('INS-2026-08-001', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-08-001', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-08-001', '1.10', NULL, NULL, NULL, NULL),
  ('INS-2026-08-001', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-08-001', '1.12', 127.70, 127.70, NULL, '2026-09-15'),
  ('INS-2026-08-001', '1.13', NULL, NULL, NULL, NULL),
  ('INS-2026-08-002', '1.1', 3299.12, 3299.12, NULL, '2026-09-11'),
  ('INS-2026-08-002', '1.2', 1343.33, 1343.33, NULL, '2026-09-10'),
  ('INS-2026-08-002', '1.3', 2302.44, 2302.44, NULL, '2026-09-11'),
  ('INS-2026-08-002', '1.4', 314.67, 314.67, NULL, '2026-09-10'),
  ('INS-2026-08-002', '1.5', 181.64, 181.64, NULL, '2026-09-10'),
  ('INS-2026-08-002', '1.6', 997.72, 997.72, NULL, '2026-09-13'),
  ('INS-2026-08-002', '1.7', 2276.86, 2276.86, NULL, '2026-09-12'),
  ('INS-2026-08-002', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-08-002', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-08-002', '1.10', 145.00, 145.00, NULL, '2026-09-10'),
  ('INS-2026-08-002', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-08-002', '1.12', 153.50, 153.50, NULL, '2026-09-13'),
  ('INS-2026-08-002', '1.13', NULL, NULL, NULL, NULL),
  ('INS-2026-08-003', '1.1', 2045.78, 2045.78, NULL, '2026-09-19'),
  ('INS-2026-08-003', '1.2', 847.99, 847.99, NULL, '2026-09-18'),
  ('INS-2026-08-003', '1.3', 1556.95, 1556.95, NULL, '2026-09-19'),
  ('INS-2026-08-003', '1.4', 212.78, 212.78, NULL, '2026-09-18'),
  ('INS-2026-08-003', '1.5', 122.83, 122.83, NULL, '2026-09-17'),
  ('INS-2026-08-003', '1.6', 674.68, 674.68, NULL, '2026-09-17'),
  ('INS-2026-08-003', '1.7', 1539.65, 1539.65, NULL, '2026-09-18'),
  ('INS-2026-08-003', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-08-003', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-08-003', '1.10', NULL, NULL, NULL, NULL),
  ('INS-2026-08-003', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-08-003', '1.12', 103.80, 103.80, NULL, '2026-09-16'),
  ('INS-2026-08-003', '1.13', 69.20, 69.20, NULL, '2026-09-17'),
  ('INS-2026-08-004', '1.1', 6528.09, 6528.09, NULL, '2026-09-13'),
  ('INS-2026-08-004', '1.2', 2130.74, 2130.74, NULL, '2026-09-10'),
  ('INS-2026-08-004', '1.3', 3145.45, 3145.45, NULL, '2026-09-13'),
  ('INS-2026-08-004', '1.4', 429.88, 429.88, NULL, '2026-09-13'),
  ('INS-2026-08-004', '1.5', 248.14, 248.14, NULL, '2026-09-12'),
  ('INS-2026-08-004', '1.6', 1363.03, 1363.03, NULL, '2026-09-13'),
  ('INS-2026-08-004', '1.7', 3110.50, 3110.50, NULL, '2026-09-12'),
  ('INS-2026-08-004', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-08-004', '1.9', NULL, NULL, NULL, NULL);
INSERT INTO DECLARA (Num_inspeccion, Cod_obligacion, Monto_declarado, Monto_pagado, Mora, Fecha_pago) VALUES
  ('INS-2026-08-004', '1.10', 237.50, 237.50, NULL, '2026-09-11'),
  ('INS-2026-08-004', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-08-004', '1.12', 209.70, 209.70, NULL, '2026-09-12'),
  ('INS-2026-08-004', '1.13', NULL, NULL, NULL, NULL),
  ('INS-2026-08-005', '1.1', 2718.70, 2718.70, NULL, '2026-09-10'),
  ('INS-2026-08-005', '1.2', 958.65, 958.65, NULL, '2026-09-13'),
  ('INS-2026-08-005', '1.3', 2215.39, 2215.39, NULL, '2026-09-11'),
  ('INS-2026-08-005', '1.4', 302.77, 302.77, NULL, '2026-09-12'),
  ('INS-2026-08-005', '1.5', 174.77, 174.77, NULL, '2026-09-10'),
  ('INS-2026-08-005', '1.6', 960.00, 960.00, NULL, '2026-09-10'),
  ('INS-2026-08-005', '1.7', 2190.77, 2190.77, NULL, '2026-09-13'),
  ('INS-2026-08-005', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-08-005', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-08-005', '1.10', NULL, NULL, NULL, NULL),
  ('INS-2026-08-005', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-08-005', '1.12', 147.69, 147.69, NULL, '2026-09-12'),
  ('INS-2026-08-005', '1.13', NULL, NULL, NULL, NULL),
  ('INS-2026-08-006', '1.1', 2731.55, 2731.55, NULL, '2026-09-13'),
  ('INS-2026-08-006', '1.2', 1234.10, 1234.10, NULL, '2026-09-14'),
  ('INS-2026-08-006', '1.3', 1656.90, 1656.90, NULL, '2026-09-12'),
  ('INS-2026-08-006', '1.4', 226.44, 226.44, NULL, '2026-09-15'),
  ('INS-2026-08-006', '1.5', 130.71, 130.71, NULL, '2026-09-14'),
  ('INS-2026-08-006', '1.6', 717.99, 717.99, NULL, '2026-09-15'),
  ('INS-2026-08-006', '1.7', 1638.49, 1638.49, NULL, '2026-09-13'),
  ('INS-2026-08-006', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-08-006', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-08-006', '1.10', NULL, NULL, NULL, NULL),
  ('INS-2026-08-006', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-08-006', '1.12', 110.46, 110.46, NULL, '2026-09-13'),
  ('INS-2026-08-006', '1.13', NULL, NULL, NULL, NULL),
  ('INS-2026-08-007', '1.1', 0.00, 0.00, NULL, '2026-09-16'),
  ('INS-2026-08-007', '1.2', 731.21, 731.21, NULL, '2026-09-17'),
  ('INS-2026-08-007', '1.3', 1180.92, 1180.92, NULL, '2026-09-16'),
  ('INS-2026-08-007', '1.4', 161.39, 161.39, NULL, '2026-09-16'),
  ('INS-2026-08-007', '1.5', 93.16, 93.16, NULL, '2026-09-17'),
  ('INS-2026-08-007', '1.6', 511.73, 511.73, NULL, '2026-09-14'),
  ('INS-2026-08-007', '1.7', 1167.80, 1167.80, NULL, '2026-09-14'),
  ('INS-2026-08-007', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-08-007', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-08-007', '1.10', NULL, NULL, NULL, NULL),
  ('INS-2026-08-007', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-08-007', '1.12', 78.73, 78.73, NULL, '2026-09-17'),
  ('INS-2026-08-007', '1.13', NULL, NULL, NULL, NULL),
  ('INS-2026-08-008', '1.1', 7084.93, 7084.93, NULL, '2026-09-16'),
  ('INS-2026-08-008', '1.2', 2283.07, 2283.07, NULL, '2026-09-19'),
  ('INS-2026-08-008', '1.3', 2828.88, 2828.88, NULL, '2026-09-17'),
  ('INS-2026-08-008', '1.4', 386.61, 386.61, NULL, '2026-09-16'),
  ('INS-2026-08-008', '1.5', 223.17, 223.17, NULL, '2026-09-18'),
  ('INS-2026-08-008', '1.6', 1225.85, 1225.85, NULL, '2026-09-19'),
  ('INS-2026-08-008', '1.7', 2797.45, 2797.45, NULL, '2026-09-18'),
  ('INS-2026-08-008', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-08-008', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-08-008', '1.10', 262.50, 262.50, NULL, '2026-09-19'),
  ('INS-2026-08-008', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-08-008', '1.12', 188.59, 188.59, NULL, '2026-09-17'),
  ('INS-2026-08-008', '1.13', NULL, NULL, NULL, NULL),
  ('INS-2026-08-009', '1.1', 7041.02, 7041.02, NULL, '2026-09-14'),
  ('INS-2026-08-009', '1.2', 2502.91, 2502.91, NULL, '2026-09-14'),
  ('INS-2026-08-009', '1.3', 2951.22, 2951.22, NULL, '2026-09-16'),
  ('INS-2026-08-009', '1.4', 403.33, 403.33, NULL, '2026-09-15'),
  ('INS-2026-08-009', '1.5', 232.82, 232.82, NULL, '2026-09-15'),
  ('INS-2026-08-009', '1.6', 1278.86, 1278.86, NULL, '2026-09-14'),
  ('INS-2026-08-009', '1.7', 2918.42, 2918.42, NULL, '2026-09-14'),
  ('INS-2026-08-009', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-08-009', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-08-009', '1.10', NULL, NULL, NULL, NULL),
  ('INS-2026-08-009', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-08-009', '1.12', 196.75, 196.75, NULL, '2026-09-16'),
  ('INS-2026-08-009', '1.13', 131.17, 131.17, NULL, '2026-09-17'),
  ('INS-2026-08-010', '1.1', 4825.72, 4825.72, NULL, '2026-09-11'),
  ('INS-2026-08-010', '1.2', 1670.46, 1670.46, NULL, '2026-09-14'),
  ('INS-2026-08-010', '1.3', 2884.12, 2884.12, NULL, '2026-09-11'),
  ('INS-2026-08-010', '1.4', 394.16, 394.16, NULL, '2026-09-11'),
  ('INS-2026-08-010', '1.5', 227.52, 227.52, NULL, '2026-09-14'),
  ('INS-2026-08-010', '1.6', 1249.78, 1249.78, NULL, '2026-09-13'),
  ('INS-2026-08-010', '1.7', 2852.07, 2852.07, NULL, '2026-09-14'),
  ('INS-2026-08-010', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-08-010', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-08-010', '1.10', NULL, NULL, NULL, NULL),
  ('INS-2026-08-010', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-08-010', '1.12', 192.27, 192.27, NULL, '2026-09-12'),
  ('INS-2026-08-010', '1.13', NULL, NULL, NULL, NULL),
  ('INS-2026-08-011', '1.1', 3733.88, 3733.88, NULL, '2026-09-13'),
  ('INS-2026-08-011', '1.2', 1086.95, 1086.95, NULL, '2026-09-12'),
  ('INS-2026-08-011', '1.3', 2357.54, 2357.54, NULL, '2026-09-14'),
  ('INS-2026-08-011', '1.4', 322.20, 322.20, NULL, '2026-09-13'),
  ('INS-2026-08-011', '1.5', 185.98, 185.98, NULL, '2026-09-11'),
  ('INS-2026-08-011', '1.6', 1021.60, 1021.60, NULL, '2026-09-14'),
  ('INS-2026-08-011', '1.7', 2331.35, 2331.35, NULL, '2026-09-14'),
  ('INS-2026-08-011', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-08-011', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-08-011', '1.10', NULL, NULL, NULL, NULL),
  ('INS-2026-08-011', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-08-011', '1.12', 157.17, 157.17, NULL, '2026-09-13'),
  ('INS-2026-08-011', '1.13', NULL, NULL, NULL, NULL),
  ('INS-2026-08-012', '1.1', 6655.69, 6655.69, NULL, '2026-09-11'),
  ('INS-2026-08-012', '1.2', 2005.01, 2005.01, NULL, '2026-09-12'),
  ('INS-2026-08-012', '1.3', 3195.09, 3195.09, NULL, '2026-09-13'),
  ('INS-2026-08-012', '1.4', 436.66, 436.66, NULL, '2026-09-10'),
  ('INS-2026-08-012', '1.5', 252.06, 252.06, NULL, '2026-09-13');
INSERT INTO DECLARA (Num_inspeccion, Cod_obligacion, Monto_declarado, Monto_pagado, Mora, Fecha_pago) VALUES
  ('INS-2026-08-012', '1.6', 1384.54, 1384.54, NULL, '2026-09-10'),
  ('INS-2026-08-012', '1.7', 3159.59, 3159.59, NULL, '2026-09-12'),
  ('INS-2026-08-012', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-08-012', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-08-012', '1.10', NULL, NULL, NULL, NULL),
  ('INS-2026-08-012', '1.11', 266.26, 266.26, NULL, '2026-09-11'),
  ('INS-2026-08-012', '1.12', 213.01, 213.01, NULL, '2026-09-11'),
  ('INS-2026-08-012', '1.13', NULL, NULL, NULL, NULL),
  ('INS-2026-08-013', '1.1', 1987.11, 1987.11, NULL, '2026-09-14'),
  ('INS-2026-08-013', '1.2', 633.39, 633.39, NULL, '2026-09-14'),
  ('INS-2026-08-013', '1.3', 1313.03, 1313.03, NULL, '2026-09-17'),
  ('INS-2026-08-013', '1.4', 179.45, 179.45, NULL, '2026-09-16'),
  ('INS-2026-08-013', '1.5', 103.58, 103.58, NULL, '2026-09-16'),
  ('INS-2026-08-013', '1.6', 568.98, 568.98, NULL, '2026-09-14'),
  ('INS-2026-08-013', '1.7', 1298.44, 1298.44, NULL, '2026-09-17'),
  ('INS-2026-08-013', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-08-013', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-08-013', '1.10', NULL, NULL, NULL, NULL),
  ('INS-2026-08-013', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-08-013', '1.12', 87.54, 87.54, NULL, '2026-09-14'),
  ('INS-2026-08-013', '1.13', NULL, NULL, NULL, NULL),
  ('INS-2026-08-014', '1.1', 4435.19, 4466.69, 31.50, '2026-09-26'),
  ('INS-2026-08-014', '1.2', 1390.18, 1390.18, NULL, '2026-09-14'),
  ('INS-2026-08-014', '1.3', 1711.58, 1711.58, NULL, '2026-09-12'),
  ('INS-2026-08-014', '1.4', 233.92, 233.92, NULL, '2026-09-13'),
  ('INS-2026-08-014', '1.5', 135.02, 135.02, NULL, '2026-09-13'),
  ('INS-2026-08-014', '1.6', 741.69, 741.69, NULL, '2026-09-13'),
  ('INS-2026-08-014', '1.7', 1692.57, 1692.57, NULL, '2026-09-12'),
  ('INS-2026-08-014', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-08-014', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-08-014', '1.10', NULL, NULL, NULL, NULL),
  ('INS-2026-08-014', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-08-014', '1.12', 114.11, 114.11, NULL, '2026-09-14'),
  ('INS-2026-08-014', '1.13', NULL, NULL, NULL, NULL),
  ('INS-2026-08-015', '1.1', 2524.13, 2524.13, NULL, '2026-09-17'),
  ('INS-2026-08-015', '1.2', 992.79, 992.79, NULL, '2026-09-16'),
  ('INS-2026-08-015', '1.3', 1847.61, 1847.61, NULL, '2026-09-19'),
  ('INS-2026-08-015', '1.4', 252.51, 252.51, NULL, '2026-09-16'),
  ('INS-2026-08-015', '1.5', 145.76, 145.76, NULL, '2026-09-17'),
  ('INS-2026-08-015', '1.6', 800.63, 800.63, NULL, '2026-09-18'),
  ('INS-2026-08-015', '1.7', 1827.08, 1827.08, NULL, '2026-09-19'),
  ('INS-2026-08-015', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-08-015', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-08-015', '1.10', NULL, NULL, NULL, NULL),
  ('INS-2026-08-015', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-08-015', '1.12', 123.17, 123.17, NULL, '2026-09-16'),
  ('INS-2026-08-015', '1.13', 82.12, 82.12, NULL, '2026-09-16'),
  ('INS-2026-08-016', '1.1', 1193.06, 1193.06, NULL, '2026-09-16'),
  ('INS-2026-08-016', '1.2', 527.67, 527.67, NULL, '2026-09-16'),
  ('INS-2026-08-016', '1.3', 1711.57, 1711.57, NULL, '2026-09-18'),
  ('INS-2026-08-016', '1.4', 233.91, 233.91, NULL, '2026-09-15'),
  ('INS-2026-08-016', '1.5', 135.02, 135.02, NULL, '2026-09-17'),
  ('INS-2026-08-016', '1.6', 741.68, 741.68, NULL, '2026-09-15'),
  ('INS-2026-08-016', '1.7', 1692.56, 1692.56, NULL, '2026-09-15'),
  ('INS-2026-08-016', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-08-016', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-08-016', '1.10', NULL, NULL, NULL, NULL),
  ('INS-2026-08-016', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-08-016', '1.12', 114.10, 114.10, NULL, '2026-09-15'),
  ('INS-2026-08-016', '1.13', NULL, NULL, NULL, NULL),
  ('INS-2026-09-001', '1.1', 1538.30, 1538.30, NULL, '2026-10-18'),
  ('INS-2026-09-001', '1.2', 844.36, 844.36, NULL, '2026-10-17'),
  ('INS-2026-09-001', '1.3', 1524.24, 1524.24, NULL, '2026-10-18'),
  ('INS-2026-09-001', '1.4', 208.31, 208.31, NULL, '2026-10-18'),
  ('INS-2026-09-001', '1.5', 120.25, 120.25, NULL, '2026-10-16'),
  ('INS-2026-09-001', '1.6', 660.50, 660.50, NULL, '2026-10-18'),
  ('INS-2026-09-001', '1.7', 1507.30, 1507.30, NULL, '2026-10-16'),
  ('INS-2026-09-001', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-09-001', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-09-001', '1.10', NULL, NULL, NULL, NULL),
  ('INS-2026-09-001', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-09-001', '1.12', 101.62, 101.62, NULL, '2026-10-19'),
  ('INS-2026-09-001', '1.13', 67.74, 67.74, NULL, '2026-10-17'),
  ('INS-2026-09-002', '1.1', 0.00, 0.00, NULL, '2026-10-17'),
  ('INS-2026-09-002', '1.2', 727.32, 727.32, NULL, '2026-10-16'),
  ('INS-2026-09-002', '1.3', 1145.87, 1145.87, NULL, '2026-10-14'),
  ('INS-2026-09-002', '1.4', 156.60, 156.60, NULL, '2026-10-16'),
  ('INS-2026-09-002', '1.5', 90.40, 90.40, NULL, '2026-10-14'),
  ('INS-2026-09-002', '1.6', 496.54, 496.54, NULL, '2026-10-14'),
  ('INS-2026-09-002', '1.7', 1133.14, 1133.14, NULL, '2026-10-15'),
  ('INS-2026-09-002', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-09-002', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-09-002', '1.10', NULL, NULL, NULL, NULL),
  ('INS-2026-09-002', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-09-002', '1.12', 76.39, 76.39, NULL, '2026-10-15'),
  ('INS-2026-09-002', '1.13', NULL, NULL, NULL, NULL),
  ('INS-2026-09-003', '1.1', 1539.49, 1539.49, NULL, '2026-10-16'),
  ('INS-2026-09-003', '1.2', 629.99, 629.99, NULL, '2026-10-15'),
  ('INS-2026-09-003', '1.3', 1282.42, 1282.42, NULL, '2026-10-16'),
  ('INS-2026-09-003', '1.4', 175.26, 175.26, NULL, '2026-10-16'),
  ('INS-2026-09-003', '1.5', 101.17, 101.17, NULL, '2026-10-15'),
  ('INS-2026-09-003', '1.6', 555.72, 555.72, NULL, '2026-10-17'),
  ('INS-2026-09-003', '1.7', 1268.17, 1268.17, NULL, '2026-10-15'),
  ('INS-2026-09-003', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-09-003', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-09-003', '1.10', NULL, NULL, NULL, NULL),
  ('INS-2026-09-003', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-09-003', '1.12', 85.49, 85.49, NULL, '2026-10-17'),
  ('INS-2026-09-003', '1.13', NULL, NULL, NULL, NULL),
  ('INS-2026-09-004', '1.1', 0.00, 0.00, NULL, '2026-10-15');
INSERT INTO DECLARA (Num_inspeccion, Cod_obligacion, Monto_declarado, Monto_pagado, Mora, Fecha_pago) VALUES
  ('INS-2026-09-004', '1.2', 640.67, 640.67, NULL, '2026-10-15'),
  ('INS-2026-09-004', '1.3', 1884.77, 1884.77, NULL, '2026-10-14'),
  ('INS-2026-09-004', '1.4', 257.59, 257.59, NULL, '2026-10-15'),
  ('INS-2026-09-004', '1.5', 148.69, 148.69, NULL, '2026-10-16'),
  ('INS-2026-09-004', '1.6', 816.74, 816.74, NULL, '2026-10-17'),
  ('INS-2026-09-004', '1.7', 1863.83, 1863.83, NULL, '2026-10-17'),
  ('INS-2026-09-004', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-09-004', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-09-004', '1.10', NULL, NULL, NULL, NULL),
  ('INS-2026-09-004', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-09-004', '1.12', 125.65, 125.65, NULL, '2026-10-15'),
  ('INS-2026-09-004', '1.13', NULL, NULL, NULL, NULL),
  ('INS-2026-09-005', '1.1', 4236.48, 4236.48, NULL, '2026-10-12'),
  ('INS-2026-09-005', '1.2', 1240.95, 1240.95, NULL, '2026-10-15'),
  ('INS-2026-09-005', '1.3', 1718.52, 1718.52, NULL, '2026-10-13'),
  ('INS-2026-09-005', '1.4', 234.86, 234.86, NULL, '2026-10-13'),
  ('INS-2026-09-005', '1.5', 135.57, 135.57, NULL, '2026-10-15'),
  ('INS-2026-09-005', '1.6', 744.69, 744.69, NULL, '2026-10-12'),
  ('INS-2026-09-005', '1.7', 1699.42, 1699.42, NULL, '2026-10-12'),
  ('INS-2026-09-005', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-09-005', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-09-005', '1.10', NULL, NULL, NULL, NULL),
  ('INS-2026-09-005', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-09-005', '1.12', 114.57, 114.57, NULL, '2026-10-12'),
  ('INS-2026-09-005', '1.13', NULL, NULL, NULL, NULL),
  ('INS-2026-09-006', '1.1', 1855.82, 1855.82, NULL, '2026-10-18'),
  ('INS-2026-09-006', '1.2', 988.22, 988.22, NULL, '2026-10-18'),
  ('INS-2026-09-006', '1.3', 1806.45, 1806.45, NULL, '2026-10-16'),
  ('INS-2026-09-006', '1.4', 246.88, 246.88, NULL, '2026-10-18'),
  ('INS-2026-09-006', '1.5', 142.51, 142.51, NULL, '2026-10-19'),
  ('INS-2026-09-006', '1.6', 782.79, 782.79, NULL, '2026-10-18'),
  ('INS-2026-09-006', '1.7', 1786.37, 1786.37, NULL, '2026-10-19'),
  ('INS-2026-09-006', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-09-006', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-09-006', '1.10', NULL, NULL, NULL, NULL),
  ('INS-2026-09-006', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-09-006', '1.12', 120.43, 120.43, NULL, '2026-10-17'),
  ('INS-2026-09-006', '1.13', 80.29, 80.29, NULL, '2026-10-17'),
  ('INS-2026-09-007', '1.1', 8138.62, 8138.62, NULL, '2026-10-18'),
  ('INS-2026-09-007', '1.2', 2287.73, 2287.73, NULL, '2026-10-18'),
  ('INS-2026-09-007', '1.3', 2870.85, 2870.85, NULL, '2026-10-17'),
  ('INS-2026-09-007', '1.4', 392.35, 392.35, NULL, '2026-10-19'),
  ('INS-2026-09-007', '1.5', 226.48, 226.48, NULL, '2026-10-19'),
  ('INS-2026-09-007', '1.6', 1244.03, 1244.03, NULL, '2026-10-16'),
  ('INS-2026-09-007', '1.7', 2838.95, 2838.95, NULL, '2026-10-16'),
  ('INS-2026-09-007', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-09-007', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-09-007', '1.10', 262.50, 262.50, NULL, '2026-10-16'),
  ('INS-2026-09-007', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-09-007', '1.12', 191.39, 191.39, NULL, '2026-10-17'),
  ('INS-2026-09-007', '1.13', NULL, NULL, NULL, NULL),
  ('INS-2026-09-008', '1.1', 3147.20, 3147.20, NULL, '2026-10-15'),
  ('INS-2026-09-008', '1.2', 1383.78, 1383.78, NULL, '2026-10-15'),
  ('INS-2026-09-008', '1.3', 1653.99, 1653.99, NULL, '2026-10-13'),
  ('INS-2026-09-008', '1.4', 226.04, 226.04, NULL, '2026-10-13'),
  ('INS-2026-09-008', '1.5', 130.48, 130.48, NULL, '2026-10-13'),
  ('INS-2026-09-008', '1.6', 716.73, 716.73, NULL, '2026-10-15'),
  ('INS-2026-09-008', '1.7', 1635.61, 1635.61, NULL, '2026-10-12'),
  ('INS-2026-09-008', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-09-008', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-09-008', '1.10', NULL, NULL, NULL, NULL),
  ('INS-2026-09-008', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-09-008', '1.12', 110.27, 110.27, NULL, '2026-10-14'),
  ('INS-2026-09-008', '1.13', NULL, NULL, NULL, NULL),
  ('INS-2026-09-009', '1.1', 5097.24, 5097.24, NULL, '2026-10-11'),
  ('INS-2026-09-009', '1.2', 1662.95, 1662.95, NULL, '2026-10-14'),
  ('INS-2026-09-009', '1.3', 2816.53, 2816.53, NULL, '2026-10-11'),
  ('INS-2026-09-009', '1.4', 384.93, 384.93, NULL, '2026-10-11'),
  ('INS-2026-09-009', '1.5', 222.19, 222.19, NULL, '2026-10-14'),
  ('INS-2026-09-009', '1.6', 1220.50, 1220.50, NULL, '2026-10-13'),
  ('INS-2026-09-009', '1.7', 2785.24, 2785.24, NULL, '2026-10-11'),
  ('INS-2026-09-009', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-09-009', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-09-009', '1.10', NULL, NULL, NULL, NULL),
  ('INS-2026-09-009', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-09-009', '1.12', 187.77, 187.77, NULL, '2026-10-14'),
  ('INS-2026-09-009', '1.13', NULL, NULL, NULL, NULL),
  ('INS-2026-09-010', '1.1', 1873.66, 1873.66, NULL, '2026-10-10'),
  ('INS-2026-09-010', '1.2', 954.02, 954.02, NULL, '2026-10-13'),
  ('INS-2026-09-010', '1.3', 2173.68, 2173.68, NULL, '2026-10-13'),
  ('INS-2026-09-010', '1.4', 297.07, 297.07, NULL, '2026-10-11'),
  ('INS-2026-09-010', '1.5', 171.48, 171.48, NULL, '2026-10-13'),
  ('INS-2026-09-010', '1.6', 941.93, 941.93, NULL, '2026-10-11'),
  ('INS-2026-09-010', '1.7', 2149.52, 2149.52, NULL, '2026-10-12'),
  ('INS-2026-09-010', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-09-010', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-09-010', '1.10', NULL, NULL, NULL, NULL),
  ('INS-2026-09-010', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-09-010', '1.12', 144.91, 144.91, NULL, '2026-10-11'),
  ('INS-2026-09-010', '1.13', NULL, NULL, NULL, NULL),
  ('INS-2026-09-011', '1.1', 1271.72, 1271.72, NULL, '2026-10-18'),
  ('INS-2026-09-011', '1.2', 517.66, 517.66, NULL, '2026-10-15'),
  ('INS-2026-09-011', '1.3', 1621.42, 1621.42, NULL, '2026-10-15'),
  ('INS-2026-09-011', '1.4', 221.59, 221.59, NULL, '2026-10-18'),
  ('INS-2026-09-011', '1.5', 127.91, 127.91, NULL, '2026-10-18'),
  ('INS-2026-09-011', '1.6', 702.62, 702.62, NULL, '2026-10-16'),
  ('INS-2026-09-011', '1.7', 1603.40, 1603.40, NULL, '2026-10-16'),
  ('INS-2026-09-011', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-09-011', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-09-011', '1.10', NULL, NULL, NULL, NULL);
INSERT INTO DECLARA (Num_inspeccion, Cod_obligacion, Monto_declarado, Monto_pagado, Mora, Fecha_pago) VALUES
  ('INS-2026-09-011', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-09-011', '1.12', 108.09, 108.09, NULL, '2026-10-18'),
  ('INS-2026-09-011', '1.13', NULL, NULL, NULL, NULL),
  ('INS-2026-09-012', '1.1', 6685.00, 6685.00, NULL, '2026-10-13'),
  ('INS-2026-09-012', '1.2', 2129.73, 2129.73, NULL, '2026-10-10'),
  ('INS-2026-09-012', '1.3', 3136.33, 3136.33, NULL, '2026-10-13'),
  ('INS-2026-09-012', '1.4', 428.63, 428.63, NULL, '2026-10-13'),
  ('INS-2026-09-012', '1.5', 247.42, 247.42, NULL, '2026-10-12'),
  ('INS-2026-09-012', '1.6', 1359.07, 1359.07, NULL, '2026-10-13'),
  ('INS-2026-09-012', '1.7', 3101.48, 3101.48, NULL, '2026-10-10'),
  ('INS-2026-09-012', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-09-012', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-09-012', '1.10', 237.50, 237.50, NULL, '2026-10-13'),
  ('INS-2026-09-012', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-09-012', '1.12', 209.09, 209.09, NULL, '2026-10-13'),
  ('INS-2026-09-012', '1.13', NULL, NULL, NULL, NULL),
  ('INS-2026-09-013', '1.1', 4792.08, 4792.08, NULL, '2026-10-12'),
  ('INS-2026-09-013', '1.2', 1349.35, 1349.35, NULL, '2026-10-13'),
  ('INS-2026-09-013', '1.3', 2356.66, 2356.66, NULL, '2026-10-12'),
  ('INS-2026-09-013', '1.4', 322.08, 322.08, NULL, '2026-10-13'),
  ('INS-2026-09-013', '1.5', 185.91, 185.91, NULL, '2026-10-13'),
  ('INS-2026-09-013', '1.6', 1021.22, 1021.22, NULL, '2026-10-13'),
  ('INS-2026-09-013', '1.7', 2330.48, 2330.48, NULL, '2026-10-11'),
  ('INS-2026-09-013', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-09-013', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-09-013', '1.10', 145.00, 145.00, NULL, '2026-10-13'),
  ('INS-2026-09-013', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-09-013', '1.12', 157.11, 157.11, NULL, '2026-10-10'),
  ('INS-2026-09-013', '1.13', NULL, NULL, NULL, NULL),
  ('INS-2026-09-014', '1.1', 6998.60, 6998.60, NULL, '2026-10-10'),
  ('INS-2026-09-014', '1.2', 2016.05, 2041.45, 25.40, '2026-10-18'),
  ('INS-2026-09-014', '1.3', 3294.42, 3294.42, NULL, '2026-10-13'),
  ('INS-2026-09-014', '1.4', 450.24, 450.24, NULL, '2026-10-12'),
  ('INS-2026-09-014', '1.5', 259.89, 259.89, NULL, '2026-10-13'),
  ('INS-2026-09-014', '1.6', 1427.58, 1427.58, NULL, '2026-10-12'),
  ('INS-2026-09-014', '1.7', 3257.82, 3257.82, NULL, '2026-10-13'),
  ('INS-2026-09-014', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-09-014', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-09-014', '1.10', NULL, NULL, NULL, NULL),
  ('INS-2026-09-014', '1.11', 274.54, 274.54, NULL, '2026-10-10'),
  ('INS-2026-09-014', '1.12', 219.63, 219.63, NULL, '2026-10-13'),
  ('INS-2026-09-014', '1.13', NULL, NULL, NULL, NULL),
  ('INS-2026-09-015', '1.1', 6472.77, 6472.77, NULL, '2026-10-17'),
  ('INS-2026-09-015', '1.2', 2502.99, 2502.99, NULL, '2026-10-17'),
  ('INS-2026-09-015', '1.3', 2951.90, 2951.90, NULL, '2026-10-15'),
  ('INS-2026-09-015', '1.4', 403.43, 403.43, NULL, '2026-10-17'),
  ('INS-2026-09-015', '1.5', 232.87, 232.87, NULL, '2026-10-15'),
  ('INS-2026-09-015', '1.6', 1279.16, 1288.96, 9.80, '2026-10-19'),
  ('INS-2026-09-015', '1.7', 2919.10, 2919.10, NULL, '2026-10-15'),
  ('INS-2026-09-015', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-09-015', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-09-015', '1.10', NULL, NULL, NULL, NULL),
  ('INS-2026-09-015', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-09-015', '1.12', 196.79, 196.79, NULL, '2026-10-16'),
  ('INS-2026-09-015', '1.13', 131.20, 131.20, NULL, '2026-10-16'),
  ('INS-2026-09-016', '1.1', 3461.82, 3461.82, NULL, '2026-10-13'),
  ('INS-2026-09-016', '1.2', 1093.96, 1093.96, NULL, '2026-10-12'),
  ('INS-2026-09-016', '1.3', 2420.64, 2420.64, NULL, '2026-10-13'),
  ('INS-2026-09-016', '1.4', 330.82, 330.82, NULL, '2026-10-11'),
  ('INS-2026-09-016', '1.5', 190.96, 190.96, NULL, '2026-10-12'),
  ('INS-2026-09-016', '1.6', 1048.94, 1048.94, NULL, '2026-10-11'),
  ('INS-2026-09-016', '1.7', 2393.74, 2393.74, NULL, '2026-10-13'),
  ('INS-2026-09-016', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-09-016', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-09-016', '1.10', NULL, NULL, NULL, NULL),
  ('INS-2026-09-016', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-09-016', '1.12', 161.38, 161.38, NULL, '2026-10-12'),
  ('INS-2026-09-016', '1.13', NULL, NULL, NULL, NULL);

-- VERIFICA (544 filas)
INSERT INTO VERIFICA (Num_inspeccion, Cod_obligacion_legal, Cumplimiento) VALUES
  ('INS-2026-01-001', '2.1', 'OK'),
  ('INS-2026-01-001', '2.2', 'OK'),
  ('INS-2026-01-001', '2.5', 'OK'),
  ('INS-2026-01-001', '2.6', 'OK'),
  ('INS-2026-01-002', '2.1', 'OK'),
  ('INS-2026-01-002', '2.2', 'OK'),
  ('INS-2026-01-002', '2.5', 'OK'),
  ('INS-2026-01-002', '2.6', 'OK'),
  ('INS-2026-01-003', '2.1', 'OK'),
  ('INS-2026-01-003', '2.2', 'OK'),
  ('INS-2026-01-003', '2.5', 'OK'),
  ('INS-2026-01-003', '2.6', 'OK'),
  ('INS-2026-01-004', '2.1', 'OK'),
  ('INS-2026-01-004', '2.2', 'OK'),
  ('INS-2026-01-004', '2.5', 'OK'),
  ('INS-2026-01-004', '2.6', 'OK'),
  ('INS-2026-01-005', '2.1', 'OK'),
  ('INS-2026-01-005', '2.2', 'OK'),
  ('INS-2026-01-005', '2.5', 'OK'),
  ('INS-2026-01-005', '2.6', 'No aplica'),
  ('INS-2026-01-006', '2.1', 'OK'),
  ('INS-2026-01-006', '2.2', 'OK'),
  ('INS-2026-01-006', '2.5', 'OK'),
  ('INS-2026-01-006', '2.6', 'OK'),
  ('INS-2026-01-007', '2.1', 'OK'),
  ('INS-2026-01-007', '2.2', 'OK'),
  ('INS-2026-01-007', '2.5', 'OK'),
  ('INS-2026-01-007', '2.6', 'OK'),
  ('INS-2026-01-008', '2.1', 'OK'),
  ('INS-2026-01-008', '2.2', 'OK'),
  ('INS-2026-01-008', '2.5', 'OK'),
  ('INS-2026-01-008', '2.6', 'OK'),
  ('INS-2026-01-009', '2.1', 'OK'),
  ('INS-2026-01-009', '2.2', 'OK'),
  ('INS-2026-01-009', '2.5', 'OK'),
  ('INS-2026-01-009', '2.6', 'OK'),
  ('INS-2026-01-010', '2.1', 'OK'),
  ('INS-2026-01-010', '2.2', 'OK'),
  ('INS-2026-01-010', '2.5', 'OK'),
  ('INS-2026-01-010', '2.6', 'OK'),
  ('INS-2026-01-011', '2.1', 'OK'),
  ('INS-2026-01-011', '2.2', 'OK'),
  ('INS-2026-01-011', '2.5', 'OK'),
  ('INS-2026-01-011', '2.6', 'OK'),
  ('INS-2026-02-001', '2.1', 'OK'),
  ('INS-2026-02-001', '2.2', 'OK'),
  ('INS-2026-02-001', '2.5', 'OK'),
  ('INS-2026-02-001', '2.6', 'OK'),
  ('INS-2026-02-002', '2.1', 'OK'),
  ('INS-2026-02-002', '2.2', 'OK'),
  ('INS-2026-02-002', '2.5', 'OK'),
  ('INS-2026-02-002', '2.6', 'OK'),
  ('INS-2026-02-003', '2.1', 'OK'),
  ('INS-2026-02-003', '2.2', 'OK'),
  ('INS-2026-02-003', '2.5', 'OK'),
  ('INS-2026-02-003', '2.6', 'OK'),
  ('INS-2026-02-004', '2.1', 'OK'),
  ('INS-2026-02-004', '2.2', 'OK'),
  ('INS-2026-02-004', '2.5', 'OK'),
  ('INS-2026-02-004', '2.6', 'OK'),
  ('INS-2026-02-005', '2.1', 'OK'),
  ('INS-2026-02-005', '2.2', 'OK'),
  ('INS-2026-02-005', '2.5', 'OK'),
  ('INS-2026-02-005', '2.6', 'OK'),
  ('INS-2026-02-006', '2.1', 'OK'),
  ('INS-2026-02-006', '2.2', 'OK'),
  ('INS-2026-02-006', '2.5', 'OK'),
  ('INS-2026-02-006', '2.6', 'OK'),
  ('INS-2026-02-007', '2.1', 'OK'),
  ('INS-2026-02-007', '2.2', 'OK'),
  ('INS-2026-02-007', '2.5', 'OK'),
  ('INS-2026-02-007', '2.6', 'OK'),
  ('INS-2026-02-008', '2.1', 'OK'),
  ('INS-2026-02-008', '2.2', 'OK'),
  ('INS-2026-02-008', '2.5', 'OK'),
  ('INS-2026-02-008', '2.6', 'No aplica'),
  ('INS-2026-02-009', '2.1', 'OK'),
  ('INS-2026-02-009', '2.2', 'OK'),
  ('INS-2026-02-009', '2.5', 'OK'),
  ('INS-2026-02-009', '2.6', 'OK'),
  ('INS-2026-02-010', '2.1', 'OK'),
  ('INS-2026-02-010', '2.2', 'OK'),
  ('INS-2026-02-010', '2.5', 'OK'),
  ('INS-2026-02-010', '2.6', 'OK'),
  ('INS-2026-02-011', '2.1', 'OK'),
  ('INS-2026-02-011', '2.2', 'OK'),
  ('INS-2026-02-011', '2.5', 'OK'),
  ('INS-2026-02-011', '2.6', 'OK'),
  ('INS-2026-02-012', '2.1', 'OK'),
  ('INS-2026-02-012', '2.2', 'OK'),
  ('INS-2026-02-012', '2.5', 'OK'),
  ('INS-2026-02-012', '2.6', 'OK'),
  ('INS-2026-02-013', '2.1', 'OK'),
  ('INS-2026-02-013', '2.2', 'OK'),
  ('INS-2026-02-013', '2.5', 'OK'),
  ('INS-2026-02-013', '2.6', 'OK'),
  ('INS-2026-02-014', '2.1', 'OK'),
  ('INS-2026-02-014', '2.2', 'OK'),
  ('INS-2026-02-014', '2.5', 'OK'),
  ('INS-2026-02-014', '2.6', 'OK');
INSERT INTO VERIFICA (Num_inspeccion, Cod_obligacion_legal, Cumplimiento) VALUES
  ('INS-2026-03-001', '2.1', 'OK'),
  ('INS-2026-03-001', '2.2', 'OK'),
  ('INS-2026-03-001', '2.5', 'OK'),
  ('INS-2026-03-001', '2.6', 'OK'),
  ('INS-2026-03-002', '2.1', 'OK'),
  ('INS-2026-03-002', '2.2', 'OK'),
  ('INS-2026-03-002', '2.5', 'OK'),
  ('INS-2026-03-002', '2.6', 'OK'),
  ('INS-2026-03-003', '2.1', 'OK'),
  ('INS-2026-03-003', '2.2', 'OK'),
  ('INS-2026-03-003', '2.5', 'OK'),
  ('INS-2026-03-003', '2.6', 'OK'),
  ('INS-2026-03-004', '2.1', 'OK'),
  ('INS-2026-03-004', '2.2', 'OK'),
  ('INS-2026-03-004', '2.5', 'OK'),
  ('INS-2026-03-004', '2.6', 'No aplica'),
  ('INS-2026-03-005', '2.1', 'OK'),
  ('INS-2026-03-005', '2.2', 'OK'),
  ('INS-2026-03-005', '2.5', 'OK'),
  ('INS-2026-03-005', '2.6', 'OK'),
  ('INS-2026-03-006', '2.1', 'OK'),
  ('INS-2026-03-006', '2.2', 'OK'),
  ('INS-2026-03-006', '2.5', 'OK'),
  ('INS-2026-03-006', '2.6', 'OK'),
  ('INS-2026-03-007', '2.1', 'OK'),
  ('INS-2026-03-007', '2.2', 'OK'),
  ('INS-2026-03-007', '2.5', 'OK'),
  ('INS-2026-03-007', '2.6', 'OK'),
  ('INS-2026-03-008', '2.1', 'OK'),
  ('INS-2026-03-008', '2.2', 'OK'),
  ('INS-2026-03-008', '2.5', 'OK'),
  ('INS-2026-03-008', '2.6', 'OK'),
  ('INS-2026-03-009', '2.1', 'OK'),
  ('INS-2026-03-009', '2.2', 'OK'),
  ('INS-2026-03-009', '2.5', 'OK'),
  ('INS-2026-03-009', '2.6', 'OK'),
  ('INS-2026-03-010', '2.1', 'OK'),
  ('INS-2026-03-010', '2.2', 'OK'),
  ('INS-2026-03-010', '2.5', 'OK'),
  ('INS-2026-03-010', '2.6', 'OK'),
  ('INS-2026-03-011', '2.1', 'OK'),
  ('INS-2026-03-011', '2.2', 'OK'),
  ('INS-2026-03-011', '2.5', 'OK'),
  ('INS-2026-03-011', '2.6', 'OK'),
  ('INS-2026-03-012', '2.1', 'OK'),
  ('INS-2026-03-012', '2.2', 'OK'),
  ('INS-2026-03-012', '2.5', 'OK'),
  ('INS-2026-03-012', '2.6', 'OK'),
  ('INS-2026-03-013', '2.1', 'OK'),
  ('INS-2026-03-013', '2.2', 'OK'),
  ('INS-2026-03-013', '2.5', 'OK'),
  ('INS-2026-03-013', '2.6', 'OK'),
  ('INS-2026-03-014', '2.1', 'OK'),
  ('INS-2026-03-014', '2.2', 'OK'),
  ('INS-2026-03-014', '2.5', 'OK'),
  ('INS-2026-03-014', '2.6', 'OK'),
  ('INS-2026-03-015', '2.1', 'OK'),
  ('INS-2026-03-015', '2.2', 'OK'),
  ('INS-2026-03-015', '2.5', 'OK'),
  ('INS-2026-03-015', '2.6', 'OK'),
  ('INS-2026-04-001', '2.1', 'OK'),
  ('INS-2026-04-001', '2.2', 'OK'),
  ('INS-2026-04-001', '2.5', 'OK'),
  ('INS-2026-04-001', '2.6', 'OK'),
  ('INS-2026-04-002', '2.1', 'OK'),
  ('INS-2026-04-002', '2.2', 'OK'),
  ('INS-2026-04-002', '2.5', 'OK'),
  ('INS-2026-04-002', '2.6', 'OK'),
  ('INS-2026-04-003', '2.1', 'OK'),
  ('INS-2026-04-003', '2.2', 'OK'),
  ('INS-2026-04-003', '2.5', 'OK'),
  ('INS-2026-04-003', '2.6', 'OK'),
  ('INS-2026-04-004', '2.1', 'OK'),
  ('INS-2026-04-004', '2.2', 'OK'),
  ('INS-2026-04-004', '2.5', 'OK'),
  ('INS-2026-04-004', '2.6', 'OK'),
  ('INS-2026-04-005', '2.1', 'OK'),
  ('INS-2026-04-005', '2.2', 'OK'),
  ('INS-2026-04-005', '2.5', 'OK'),
  ('INS-2026-04-005', '2.6', 'No aplica'),
  ('INS-2026-04-006', '2.1', 'OK'),
  ('INS-2026-04-006', '2.2', 'OK'),
  ('INS-2026-04-006', '2.5', 'OK'),
  ('INS-2026-04-006', '2.6', 'No aplica'),
  ('INS-2026-04-007', '2.1', 'OK'),
  ('INS-2026-04-007', '2.2', 'OK'),
  ('INS-2026-04-007', '2.5', 'OK'),
  ('INS-2026-04-007', '2.6', 'OK'),
  ('INS-2026-04-008', '2.1', 'OK'),
  ('INS-2026-04-008', '2.2', 'OK'),
  ('INS-2026-04-008', '2.5', 'OK'),
  ('INS-2026-04-008', '2.6', 'OK'),
  ('INS-2026-04-009', '2.1', 'OK'),
  ('INS-2026-04-009', '2.2', 'OK'),
  ('INS-2026-04-009', '2.5', 'OK'),
  ('INS-2026-04-009', '2.6', 'OK'),
  ('INS-2026-04-010', '2.1', 'OK'),
  ('INS-2026-04-010', '2.2', 'OK'),
  ('INS-2026-04-010', '2.5', 'OK'),
  ('INS-2026-04-010', '2.6', 'OK');
INSERT INTO VERIFICA (Num_inspeccion, Cod_obligacion_legal, Cumplimiento) VALUES
  ('INS-2026-04-011', '2.1', 'OK'),
  ('INS-2026-04-011', '2.2', 'OK'),
  ('INS-2026-04-011', '2.5', 'OK'),
  ('INS-2026-04-011', '2.6', 'OK'),
  ('INS-2026-04-012', '2.1', 'OK'),
  ('INS-2026-04-012', '2.2', 'OK'),
  ('INS-2026-04-012', '2.5', 'OK'),
  ('INS-2026-04-012', '2.6', 'OK'),
  ('INS-2026-04-013', '2.1', 'OK'),
  ('INS-2026-04-013', '2.2', 'OK'),
  ('INS-2026-04-013', '2.5', 'OK'),
  ('INS-2026-04-013', '2.6', 'OK'),
  ('INS-2026-04-014', '2.1', 'OK'),
  ('INS-2026-04-014', '2.2', 'OK'),
  ('INS-2026-04-014', '2.5', 'OK'),
  ('INS-2026-04-014', '2.6', 'OK'),
  ('INS-2026-04-015', '2.1', 'OK'),
  ('INS-2026-04-015', '2.2', 'OK'),
  ('INS-2026-04-015', '2.5', 'OK'),
  ('INS-2026-04-015', '2.6', 'OK'),
  ('INS-2026-05-001', '2.1', 'OK'),
  ('INS-2026-05-001', '2.2', 'OK'),
  ('INS-2026-05-001', '2.5', 'OK'),
  ('INS-2026-05-001', '2.6', 'OK'),
  ('INS-2026-05-002', '2.1', 'OK'),
  ('INS-2026-05-002', '2.2', 'OK'),
  ('INS-2026-05-002', '2.5', 'OK'),
  ('INS-2026-05-002', '2.6', 'OK'),
  ('INS-2026-05-003', '2.1', 'OK'),
  ('INS-2026-05-003', '2.2', 'OK'),
  ('INS-2026-05-003', '2.5', 'OK'),
  ('INS-2026-05-003', '2.6', 'OK'),
  ('INS-2026-05-004', '2.1', 'OK'),
  ('INS-2026-05-004', '2.2', 'OK'),
  ('INS-2026-05-004', '2.5', 'OK'),
  ('INS-2026-05-004', '2.6', 'OK'),
  ('INS-2026-05-005', '2.1', 'OK'),
  ('INS-2026-05-005', '2.2', 'OK'),
  ('INS-2026-05-005', '2.5', 'OK'),
  ('INS-2026-05-005', '2.6', 'No aplica'),
  ('INS-2026-05-006', '2.1', 'OK'),
  ('INS-2026-05-006', '2.2', 'OK'),
  ('INS-2026-05-006', '2.5', 'OK'),
  ('INS-2026-05-006', '2.6', 'OK'),
  ('INS-2026-05-007', '2.1', 'OK'),
  ('INS-2026-05-007', '2.2', 'OK'),
  ('INS-2026-05-007', '2.5', 'OK'),
  ('INS-2026-05-007', '2.6', 'OK'),
  ('INS-2026-05-008', '2.1', 'OK'),
  ('INS-2026-05-008', '2.2', 'OK'),
  ('INS-2026-05-008', '2.5', 'OK'),
  ('INS-2026-05-008', '2.6', 'OK'),
  ('INS-2026-05-009', '2.1', 'OK'),
  ('INS-2026-05-009', '2.2', 'OK'),
  ('INS-2026-05-009', '2.5', 'OK'),
  ('INS-2026-05-009', '2.6', 'OK'),
  ('INS-2026-05-010', '2.1', 'OK'),
  ('INS-2026-05-010', '2.2', 'OK'),
  ('INS-2026-05-010', '2.5', 'OK'),
  ('INS-2026-05-010', '2.6', 'OK'),
  ('INS-2026-05-011', '2.1', 'OK'),
  ('INS-2026-05-011', '2.2', 'OK'),
  ('INS-2026-05-011', '2.5', 'OK'),
  ('INS-2026-05-011', '2.6', 'OK'),
  ('INS-2026-05-012', '2.1', 'OK'),
  ('INS-2026-05-012', '2.2', 'OK'),
  ('INS-2026-05-012', '2.5', 'OK'),
  ('INS-2026-05-012', '2.6', 'OK'),
  ('INS-2026-05-013', '2.1', 'OK'),
  ('INS-2026-05-013', '2.2', 'OK'),
  ('INS-2026-05-013', '2.5', 'OK'),
  ('INS-2026-05-013', '2.6', 'No aplica'),
  ('INS-2026-05-014', '2.1', 'OK'),
  ('INS-2026-05-014', '2.2', 'OK'),
  ('INS-2026-05-014', '2.5', 'OK'),
  ('INS-2026-05-014', '2.6', 'OK'),
  ('INS-2026-05-015', '2.1', 'OK'),
  ('INS-2026-05-015', '2.2', 'OK'),
  ('INS-2026-05-015', '2.5', 'OK'),
  ('INS-2026-05-015', '2.6', 'No aplica'),
  ('INS-2026-05-016', '2.1', 'OK'),
  ('INS-2026-05-016', '2.2', 'OK'),
  ('INS-2026-05-016', '2.5', 'OK'),
  ('INS-2026-05-016', '2.6', 'OK'),
  ('INS-2026-05-017', '2.1', 'OK'),
  ('INS-2026-05-017', '2.2', 'OK'),
  ('INS-2026-05-017', '2.5', 'OK'),
  ('INS-2026-05-017', '2.6', 'OK'),
  ('INS-2026-06-001', '2.1', 'OK'),
  ('INS-2026-06-001', '2.2', 'OK'),
  ('INS-2026-06-001', '2.5', 'OK'),
  ('INS-2026-06-001', '2.6', 'OK'),
  ('INS-2026-06-002', '2.1', 'OK'),
  ('INS-2026-06-002', '2.2', 'OK'),
  ('INS-2026-06-002', '2.5', 'OK'),
  ('INS-2026-06-002', '2.6', 'OK'),
  ('INS-2026-06-003', '2.1', 'OK'),
  ('INS-2026-06-003', '2.2', 'OK'),
  ('INS-2026-06-003', '2.5', 'OK'),
  ('INS-2026-06-003', '2.6', 'OK');
INSERT INTO VERIFICA (Num_inspeccion, Cod_obligacion_legal, Cumplimiento) VALUES
  ('INS-2026-06-004', '2.1', 'OK'),
  ('INS-2026-06-004', '2.2', 'OK'),
  ('INS-2026-06-004', '2.5', 'OK'),
  ('INS-2026-06-004', '2.6', 'OK'),
  ('INS-2026-06-005', '2.1', 'OK'),
  ('INS-2026-06-005', '2.2', 'OK'),
  ('INS-2026-06-005', '2.5', 'OK'),
  ('INS-2026-06-005', '2.6', 'OK'),
  ('INS-2026-06-006', '2.1', 'OK'),
  ('INS-2026-06-006', '2.2', 'OK'),
  ('INS-2026-06-006', '2.5', 'OK'),
  ('INS-2026-06-006', '2.6', 'OK'),
  ('INS-2026-06-007', '2.1', 'OK'),
  ('INS-2026-06-007', '2.2', 'OK'),
  ('INS-2026-06-007', '2.5', 'OK'),
  ('INS-2026-06-007', '2.6', 'OK'),
  ('INS-2026-06-008', '2.1', 'OK'),
  ('INS-2026-06-008', '2.2', 'OK'),
  ('INS-2026-06-008', '2.5', 'OK'),
  ('INS-2026-06-008', '2.6', 'OK'),
  ('INS-2026-06-009', '2.1', 'OK'),
  ('INS-2026-06-009', '2.2', 'OK'),
  ('INS-2026-06-009', '2.5', 'OK'),
  ('INS-2026-06-009', '2.6', 'OK'),
  ('INS-2026-06-010', '2.1', 'OK'),
  ('INS-2026-06-010', '2.2', 'OK'),
  ('INS-2026-06-010', '2.5', 'OK'),
  ('INS-2026-06-010', '2.6', 'No aplica'),
  ('INS-2026-06-011', '2.1', 'OK'),
  ('INS-2026-06-011', '2.2', 'OK'),
  ('INS-2026-06-011', '2.5', 'OK'),
  ('INS-2026-06-011', '2.6', 'No aplica'),
  ('INS-2026-06-012', '2.1', 'OK'),
  ('INS-2026-06-012', '2.2', 'OK'),
  ('INS-2026-06-012', '2.5', 'OK'),
  ('INS-2026-06-012', '2.6', 'OK'),
  ('INS-2026-06-013', '2.1', 'OK'),
  ('INS-2026-06-013', '2.2', 'OK'),
  ('INS-2026-06-013', '2.5', 'OK'),
  ('INS-2026-06-013', '2.6', 'OK'),
  ('INS-2026-06-014', '2.1', 'OK'),
  ('INS-2026-06-014', '2.2', 'OK'),
  ('INS-2026-06-014', '2.5', 'OK'),
  ('INS-2026-06-014', '2.6', 'OK'),
  ('INS-2026-06-015', '2.1', 'OK'),
  ('INS-2026-06-015', '2.2', 'OK'),
  ('INS-2026-06-015', '2.5', 'OK'),
  ('INS-2026-06-015', '2.6', 'OK'),
  ('INS-2026-06-016', '2.1', 'OK'),
  ('INS-2026-06-016', '2.2', 'OK'),
  ('INS-2026-06-016', '2.5', 'OK'),
  ('INS-2026-06-016', '2.6', 'OK'),
  ('INS-2026-07-001', '2.1', 'OK'),
  ('INS-2026-07-001', '2.2', 'OK'),
  ('INS-2026-07-001', '2.5', 'OK'),
  ('INS-2026-07-001', '2.6', 'OK'),
  ('INS-2026-07-002', '2.1', 'OK'),
  ('INS-2026-07-002', '2.2', 'OK'),
  ('INS-2026-07-002', '2.5', 'OK'),
  ('INS-2026-07-002', '2.6', 'OK'),
  ('INS-2026-07-003', '2.1', 'OK'),
  ('INS-2026-07-003', '2.2', 'OK'),
  ('INS-2026-07-003', '2.5', 'OK'),
  ('INS-2026-07-003', '2.6', 'OK'),
  ('INS-2026-07-004', '2.1', 'OK'),
  ('INS-2026-07-004', '2.2', 'OK'),
  ('INS-2026-07-004', '2.5', 'OK'),
  ('INS-2026-07-004', '2.6', 'OK'),
  ('INS-2026-07-005', '2.1', 'OK'),
  ('INS-2026-07-005', '2.2', 'OK'),
  ('INS-2026-07-005', '2.5', 'OK'),
  ('INS-2026-07-005', '2.6', 'OK'),
  ('INS-2026-07-006', '2.1', 'OK'),
  ('INS-2026-07-006', '2.2', 'OK'),
  ('INS-2026-07-006', '2.5', 'OK'),
  ('INS-2026-07-006', '2.6', 'OK'),
  ('INS-2026-07-007', '2.1', 'OK'),
  ('INS-2026-07-007', '2.2', 'OK'),
  ('INS-2026-07-007', '2.5', 'OK'),
  ('INS-2026-07-007', '2.6', 'OK'),
  ('INS-2026-07-008', '2.1', 'OK'),
  ('INS-2026-07-008', '2.2', 'OK'),
  ('INS-2026-07-008', '2.5', 'OK'),
  ('INS-2026-07-008', '2.6', 'OK'),
  ('INS-2026-07-009', '2.1', 'OK'),
  ('INS-2026-07-009', '2.2', 'OK'),
  ('INS-2026-07-009', '2.5', 'OK'),
  ('INS-2026-07-009', '2.6', 'OK'),
  ('INS-2026-07-010', '2.1', 'OK'),
  ('INS-2026-07-010', '2.2', 'OK'),
  ('INS-2026-07-010', '2.5', 'OK'),
  ('INS-2026-07-010', '2.6', 'OK'),
  ('INS-2026-07-011', '2.1', 'OK'),
  ('INS-2026-07-011', '2.2', 'OK'),
  ('INS-2026-07-011', '2.5', 'OK'),
  ('INS-2026-07-011', '2.6', 'No aplica'),
  ('INS-2026-07-012', '2.1', 'OK'),
  ('INS-2026-07-012', '2.2', 'OK'),
  ('INS-2026-07-012', '2.5', 'OK'),
  ('INS-2026-07-012', '2.6', 'OK');
INSERT INTO VERIFICA (Num_inspeccion, Cod_obligacion_legal, Cumplimiento) VALUES
  ('INS-2026-07-013', '2.1', 'OK'),
  ('INS-2026-07-013', '2.2', 'OK'),
  ('INS-2026-07-013', '2.5', 'OK'),
  ('INS-2026-07-013', '2.6', 'OK'),
  ('INS-2026-07-014', '2.1', 'OK'),
  ('INS-2026-07-014', '2.2', 'OK'),
  ('INS-2026-07-014', '2.5', 'OK'),
  ('INS-2026-07-014', '2.6', 'OK'),
  ('INS-2026-07-015', '2.1', 'OK'),
  ('INS-2026-07-015', '2.2', 'OK'),
  ('INS-2026-07-015', '2.5', 'OK'),
  ('INS-2026-07-015', '2.6', 'No aplica'),
  ('INS-2026-07-016', '2.1', 'OK'),
  ('INS-2026-07-016', '2.2', 'OK'),
  ('INS-2026-07-016', '2.5', 'OK'),
  ('INS-2026-07-016', '2.6', 'OK'),
  ('INS-2026-08-001', '2.1', 'OK'),
  ('INS-2026-08-001', '2.2', 'OK'),
  ('INS-2026-08-001', '2.5', 'OK'),
  ('INS-2026-08-001', '2.6', 'No aplica'),
  ('INS-2026-08-002', '2.1', 'OK'),
  ('INS-2026-08-002', '2.2', 'OK'),
  ('INS-2026-08-002', '2.5', 'OK'),
  ('INS-2026-08-002', '2.6', 'OK'),
  ('INS-2026-08-003', '2.1', 'OK'),
  ('INS-2026-08-003', '2.2', 'OK'),
  ('INS-2026-08-003', '2.5', 'OK'),
  ('INS-2026-08-003', '2.6', 'OK'),
  ('INS-2026-08-004', '2.1', 'OK'),
  ('INS-2026-08-004', '2.2', 'OK'),
  ('INS-2026-08-004', '2.5', 'OK'),
  ('INS-2026-08-004', '2.6', 'OK'),
  ('INS-2026-08-005', '2.1', 'OK'),
  ('INS-2026-08-005', '2.2', 'OK'),
  ('INS-2026-08-005', '2.5', 'OK'),
  ('INS-2026-08-005', '2.6', 'OK'),
  ('INS-2026-08-006', '2.1', 'OK'),
  ('INS-2026-08-006', '2.2', 'OK'),
  ('INS-2026-08-006', '2.5', 'OK'),
  ('INS-2026-08-006', '2.6', 'OK'),
  ('INS-2026-08-007', '2.1', 'OK'),
  ('INS-2026-08-007', '2.2', 'OK'),
  ('INS-2026-08-007', '2.5', 'OK'),
  ('INS-2026-08-007', '2.6', 'OK'),
  ('INS-2026-08-008', '2.1', 'OK'),
  ('INS-2026-08-008', '2.2', 'OK'),
  ('INS-2026-08-008', '2.5', 'OK'),
  ('INS-2026-08-008', '2.6', 'OK'),
  ('INS-2026-08-009', '2.1', 'OK'),
  ('INS-2026-08-009', '2.2', 'OK'),
  ('INS-2026-08-009', '2.5', 'OK'),
  ('INS-2026-08-009', '2.6', 'OK'),
  ('INS-2026-08-010', '2.1', 'OK'),
  ('INS-2026-08-010', '2.2', 'OK'),
  ('INS-2026-08-010', '2.5', 'OK'),
  ('INS-2026-08-010', '2.6', 'OK'),
  ('INS-2026-08-011', '2.1', 'OK'),
  ('INS-2026-08-011', '2.2', 'OK'),
  ('INS-2026-08-011', '2.5', 'OK'),
  ('INS-2026-08-011', '2.6', 'OK'),
  ('INS-2026-08-012', '2.1', 'OK'),
  ('INS-2026-08-012', '2.2', 'OK'),
  ('INS-2026-08-012', '2.5', 'OK'),
  ('INS-2026-08-012', '2.6', 'OK'),
  ('INS-2026-08-013', '2.1', 'OK'),
  ('INS-2026-08-013', '2.2', 'OK'),
  ('INS-2026-08-013', '2.5', 'OK'),
  ('INS-2026-08-013', '2.6', 'OK'),
  ('INS-2026-08-014', '2.1', 'OK'),
  ('INS-2026-08-014', '2.2', 'OK'),
  ('INS-2026-08-014', '2.5', 'OK'),
  ('INS-2026-08-014', '2.6', 'OK'),
  ('INS-2026-08-015', '2.1', 'OK'),
  ('INS-2026-08-015', '2.2', 'OK'),
  ('INS-2026-08-015', '2.5', 'OK'),
  ('INS-2026-08-015', '2.6', 'OK'),
  ('INS-2026-08-016', '2.1', 'OK'),
  ('INS-2026-08-016', '2.2', 'OK'),
  ('INS-2026-08-016', '2.5', 'OK'),
  ('INS-2026-08-016', '2.6', 'No aplica'),
  ('INS-2026-09-001', '2.1', 'OK'),
  ('INS-2026-09-001', '2.2', 'OK'),
  ('INS-2026-09-001', '2.5', 'OK'),
  ('INS-2026-09-001', '2.6', 'OK'),
  ('INS-2026-09-002', '2.1', 'OK'),
  ('INS-2026-09-002', '2.2', 'OK'),
  ('INS-2026-09-002', '2.5', 'OK'),
  ('INS-2026-09-002', '2.6', 'OK'),
  ('INS-2026-09-003', '2.1', 'OK'),
  ('INS-2026-09-003', '2.2', 'OK'),
  ('INS-2026-09-003', '2.5', 'OK'),
  ('INS-2026-09-003', '2.6', 'OK'),
  ('INS-2026-09-004', '2.1', 'OK'),
  ('INS-2026-09-004', '2.2', 'OK'),
  ('INS-2026-09-004', '2.5', 'OK'),
  ('INS-2026-09-004', '2.6', 'No aplica'),
  ('INS-2026-09-005', '2.1', 'OK'),
  ('INS-2026-09-005', '2.2', 'OK'),
  ('INS-2026-09-005', '2.5', 'OK'),
  ('INS-2026-09-005', '2.6', 'OK');
INSERT INTO VERIFICA (Num_inspeccion, Cod_obligacion_legal, Cumplimiento) VALUES
  ('INS-2026-09-006', '2.1', 'OK'),
  ('INS-2026-09-006', '2.2', 'OK'),
  ('INS-2026-09-006', '2.5', 'OK'),
  ('INS-2026-09-006', '2.6', 'OK'),
  ('INS-2026-09-007', '2.1', 'OK'),
  ('INS-2026-09-007', '2.2', 'OK'),
  ('INS-2026-09-007', '2.5', 'OK'),
  ('INS-2026-09-007', '2.6', 'OK'),
  ('INS-2026-09-008', '2.1', 'OK'),
  ('INS-2026-09-008', '2.2', 'OK'),
  ('INS-2026-09-008', '2.5', 'OK'),
  ('INS-2026-09-008', '2.6', 'OK'),
  ('INS-2026-09-009', '2.1', 'OK'),
  ('INS-2026-09-009', '2.2', 'OK'),
  ('INS-2026-09-009', '2.5', 'OK'),
  ('INS-2026-09-009', '2.6', 'OK'),
  ('INS-2026-09-010', '2.1', 'OK'),
  ('INS-2026-09-010', '2.2', 'OK'),
  ('INS-2026-09-010', '2.5', 'OK'),
  ('INS-2026-09-010', '2.6', 'OK'),
  ('INS-2026-09-011', '2.1', 'OK'),
  ('INS-2026-09-011', '2.2', 'OK'),
  ('INS-2026-09-011', '2.5', 'OK'),
  ('INS-2026-09-011', '2.6', 'No aplica'),
  ('INS-2026-09-012', '2.1', 'OK'),
  ('INS-2026-09-012', '2.2', 'OK'),
  ('INS-2026-09-012', '2.5', 'OK'),
  ('INS-2026-09-012', '2.6', 'OK'),
  ('INS-2026-09-013', '2.1', 'OK'),
  ('INS-2026-09-013', '2.2', 'OK'),
  ('INS-2026-09-013', '2.5', 'OK'),
  ('INS-2026-09-013', '2.6', 'OK'),
  ('INS-2026-09-014', '2.1', 'OK'),
  ('INS-2026-09-014', '2.2', 'OK'),
  ('INS-2026-09-014', '2.5', 'OK'),
  ('INS-2026-09-014', '2.6', 'OK'),
  ('INS-2026-09-015', '2.1', 'OK'),
  ('INS-2026-09-015', '2.2', 'OK'),
  ('INS-2026-09-015', '2.5', 'OK'),
  ('INS-2026-09-015', '2.6', 'OK'),
  ('INS-2026-09-016', '2.1', 'OK'),
  ('INS-2026-09-016', '2.2', 'OK'),
  ('INS-2026-09-016', '2.5', 'OK'),
  ('INS-2026-09-016', '2.6', 'OK');

-- RESPALDA (1221 filas)
INSERT INTO RESPALDA (Num_reporte, Cod_obligacion, Monto_adeudado, Monto_pagado_rep) VALUES
  ('REP-202601-0001', '1.1', 0.00, 0.00),
  ('REP-202601-0001', '1.2', 727.82, 727.82),
  ('REP-202601-0001', '1.3', 1150.35, 1150.35),
  ('REP-202601-0001', '1.6', 498.48, 498.48),
  ('REP-202601-0002', '1.7', 1137.57, 1137.57),
  ('REP-202601-0003', '1.4', 157.21, 157.21),
  ('REP-202601-0003', '1.5', 90.75, 90.75),
  ('REP-202601-0003', '1.12', 76.69, 76.69),
  ('REP-202601-0004', '1.1', 4673.63, 4673.63),
  ('REP-202601-0004', '1.2', 2126.57, 2126.57),
  ('REP-202601-0004', '1.3', 3107.87, 3107.87),
  ('REP-202601-0004', '1.6', 1346.74, 1346.74),
  ('REP-202601-0005', '1.7', 1844.00, 1844.00),
  ('REP-202601-0006', '1.7', 1229.34, 1229.34),
  ('REP-202601-0007', '1.4', 424.74, 424.74),
  ('REP-202601-0007', '1.5', 245.18, 245.18),
  ('REP-202601-0007', '1.12', 207.19, 207.19),
  ('REP-202601-0008', '1.10', 237.50, 237.50),
  ('REP-202601-0009', '1.1', 4842.52, 4842.52),
  ('REP-202601-0009', '1.2', 2001.94, 2001.94),
  ('REP-202601-0009', '1.3', 3167.50, 3167.50),
  ('REP-202601-0009', '1.6', 1372.58, 1372.58),
  ('REP-202601-0010', '1.7', 1879.38, 1879.38),
  ('REP-202601-0011', '1.7', 1252.92, 1252.92),
  ('REP-202601-0012', '1.4', 432.89, 432.89),
  ('REP-202601-0012', '1.5', 249.88, 249.88),
  ('REP-202601-0012', '1.12', 211.17, 211.17),
  ('REP-202601-0013', '1.11', 263.96, 263.96),
  ('REP-202601-0014', '1.1', 8667.24, 8667.24),
  ('REP-202601-0014', '1.2', 2502.54, 2502.54),
  ('REP-202601-0014', '1.3', 2947.85, 2947.85),
  ('REP-202601-0014', '1.6', 1277.40, 1277.40),
  ('REP-202601-0015', '1.7', 1749.06, 1749.06),
  ('REP-202601-0016', '1.7', 1166.04, 1166.04),
  ('REP-202601-0017', '1.4', 402.87, 402.87),
  ('REP-202601-0017', '1.5', 232.55, 232.55),
  ('REP-202601-0017', '1.12', 196.52, 196.52),
  ('REP-202601-0017', '1.13', 131.02, 131.02),
  ('REP-202601-0018', '1.1', 0.00, 0.00),
  ('REP-202601-0018', '1.2', 638.92, 638.92),
  ('REP-202601-0018', '1.3', 1869.05, 1869.05),
  ('REP-202601-0018', '1.6', 809.92, 809.92),
  ('REP-202601-0019', '1.7', 1848.28, 1848.28),
  ('REP-202601-0020', '1.4', 255.44, 255.44),
  ('REP-202601-0020', '1.5', 147.45, 147.45),
  ('REP-202601-0020', '1.12', 124.60, 124.60),
  ('REP-202601-0021', '1.1', 4445.04, 4445.04),
  ('REP-202601-0021', '1.2', 1380.64, 1380.64),
  ('REP-202601-0021', '1.3', 1625.79, 1625.79),
  ('REP-202601-0021', '1.6', 704.51, 704.51),
  ('REP-202601-0022', '1.7', 964.64, 964.64),
  ('REP-202601-0023', '1.7', 643.09, 643.09),
  ('REP-202601-0024', '1.4', 222.19, 222.19),
  ('REP-202601-0024', '1.5', 128.26, 128.26),
  ('REP-202601-0024', '1.12', 108.39, 108.39),
  ('REP-202601-0025', '1.1', 2398.76, 2398.76),
  ('REP-202601-0025', '1.2', 984.91, 984.91),
  ('REP-202601-0025', '1.3', 1776.70, 1776.70),
  ('REP-202601-0025', '1.6', 769.90, 769.90),
  ('REP-202601-0026', '1.7', 1054.18, 1054.18),
  ('REP-202601-0027', '1.7', 702.78, 702.78),
  ('REP-202601-0028', '1.4', 242.82, 242.82),
  ('REP-202601-0028', '1.5', 140.16, 140.16),
  ('REP-202601-0028', '1.12', 118.45, 118.45),
  ('REP-202601-0028', '1.13', 78.96, 78.96),
  ('REP-202601-0029', '1.1', 2414.01, 2414.01),
  ('REP-202601-0029', '1.2', 1242.42, 1242.42),
  ('REP-202601-0029', '1.3', 1731.81, 1731.81),
  ('REP-202601-0029', '1.6', 750.45, 750.45),
  ('REP-202601-0030', '1.7', 1027.54, 1027.54),
  ('REP-202601-0031', '1.7', 685.02, 685.02),
  ('REP-202601-0032', '1.4', 236.68, 236.68),
  ('REP-202601-0032', '1.5', 136.62, 136.62),
  ('REP-202601-0032', '1.12', 115.45, 115.45),
  ('REP-202601-0033', '1.1', 3098.40, 3098.40),
  ('REP-202601-0033', '1.2', 955.75, 955.75),
  ('REP-202601-0033', '1.3', 2189.27, 2189.27),
  ('REP-202601-0033', '1.6', 948.68, 948.68),
  ('REP-202601-0034', '1.7', 2164.94, 2164.94),
  ('REP-202601-0035', '1.4', 299.20, 299.20),
  ('REP-202601-0035', '1.5', 172.71, 172.71),
  ('REP-202601-0035', '1.12', 145.95, 145.95),
  ('REP-202601-0036', '1.1', 3018.73, 3018.73),
  ('REP-202601-0036', '1.2', 841.20, 841.20),
  ('REP-202601-0036', '1.3', 1495.84, 1495.84),
  ('REP-202601-0036', '1.6', 648.20, 648.20),
  ('REP-202601-0037', '1.7', 887.53, 887.53),
  ('REP-202601-0038', '1.7', 591.69, 591.69),
  ('REP-202601-0039', '1.4', 204.43, 204.43),
  ('REP-202601-0039', '1.5', 118.01, 118.01),
  ('REP-202601-0039', '1.12', 99.72, 99.72),
  ('REP-202601-0039', '1.13', 66.48, 66.48),
  ('REP-202601-0040', '1.1', 6223.19, 6223.19),
  ('REP-202601-0040', '1.2', 1670.14, 1670.14),
  ('REP-202601-0040', '1.3', 2881.24, 2881.24),
  ('REP-202601-0040', '1.6', 1248.54, 1248.54),
  ('REP-202601-0041', '1.7', 2849.22, 2849.22),
  ('REP-202601-0042', '1.4', 393.77, 393.77),
  ('REP-202601-0042', '1.5', 227.30, 227.30),
  ('REP-202601-0042', '1.12', 192.08, 192.08);
INSERT INTO RESPALDA (Num_reporte, Cod_obligacion, Monto_adeudado, Monto_pagado_rep) VALUES
  ('REP-202602-0001', '1.1', 1833.74, 1833.74),
  ('REP-202602-0001', '1.2', 946.17, 946.17),
  ('REP-202602-0001', '1.3', 2103.03, 2103.03),
  ('REP-202602-0001', '1.6', 911.31, 911.31),
  ('REP-202602-0002', '1.7', 2079.66, 2079.66),
  ('REP-202602-0003', '1.4', 287.41, 287.41),
  ('REP-202602-0003', '1.5', 165.91, 165.91),
  ('REP-202602-0003', '1.12', 140.20, 140.20),
  ('REP-202602-0004', '1.1', 2331.19, 2331.19),
  ('REP-202602-0004', '1.2', 1348.48, 1348.48),
  ('REP-202602-0004', '1.3', 2348.85, 2348.85),
  ('REP-202602-0004', '1.6', 1017.84, 1017.84),
  ('REP-202602-0005', '1.7', 1393.66, 1393.66),
  ('REP-202602-0006', '1.7', 929.10, 929.10),
  ('REP-202602-0007', '1.4', 321.01, 321.01),
  ('REP-202602-0007', '1.5', 185.30, 185.30),
  ('REP-202602-0007', '1.12', 156.59, 156.59),
  ('REP-202602-0008', '1.10', 145.00, 145.00),
  ('REP-202602-0009', '1.1', 0.00, 0.00),
  ('REP-202602-0009', '1.2', 730.96, 730.96),
  ('REP-202602-0009', '1.3', 1178.65, 1178.65),
  ('REP-202602-0009', '1.6', 510.75, 510.75),
  ('REP-202602-0010', '1.7', 1165.56, 1165.56),
  ('REP-202602-0011', '1.4', 161.08, 161.08),
  ('REP-202602-0011', '1.5', 92.98, 92.98),
  ('REP-202602-0011', '1.12', 78.58, 78.58),
  ('REP-202602-0012', '1.1', 4773.95, 4773.95),
  ('REP-202602-0012', '1.2', 1238.53, 1238.53),
  ('REP-202602-0012', '1.3', 1696.78, 1696.78),
  ('REP-202602-0012', '1.6', 735.27, 735.27),
  ('REP-202602-0013', '1.7', 1006.76, 1006.76),
  ('REP-202602-0014', '1.7', 671.17, 671.17),
  ('REP-202602-0015', '1.4', 231.89, 231.89),
  ('REP-202602-0015', '1.5', 133.86, 133.86),
  ('REP-202602-0015', '1.12', 113.12, 113.12),
  ('REP-202602-0016', '1.1', 3603.64, 3603.64),
  ('REP-202602-0016', '1.2', 2123.45, 2123.45),
  ('REP-202602-0016', '1.3', 3079.76, 3079.76),
  ('REP-202602-0016', '1.6', 1334.56, 1334.56),
  ('REP-202602-0017', '1.7', 1827.32, 1827.32),
  ('REP-202602-0018', '1.7', 1218.22, 1218.22),
  ('REP-202602-0019', '1.4', 420.90, 420.90),
  ('REP-202602-0019', '1.5', 242.96, 242.96),
  ('REP-202602-0019', '1.12', 205.32, 205.32),
  ('REP-202602-0020', '1.10', 237.50, 237.50),
  ('REP-202602-0021', '1.1', 7872.19, 7872.19),
  ('REP-202602-0021', '1.2', 2281.38, 2281.38),
  ('REP-202602-0021', '1.3', 2813.69, 2813.69),
  ('REP-202602-0021', '1.6', 1219.27, 1219.27),
  ('REP-202602-0022', '1.7', 2782.43, 2782.43),
  ('REP-202602-0023', '1.4', 384.54, 384.54),
  ('REP-202602-0023', '1.5', 221.97, 221.97),
  ('REP-202602-0023', '1.12', 187.58, 187.58),
  ('REP-202602-0024', '1.10', 262.50, 262.50),
  ('REP-202602-0025', '1.1', 3131.42, 3131.42),
  ('REP-202602-0025', '1.2', 1669.46, 1669.46),
  ('REP-202602-0025', '1.3', 2875.13, 2875.13),
  ('REP-202602-0025', '1.6', 1245.89, 1245.89),
  ('REP-202602-0026', '1.7', 2843.19, 2843.19),
  ('REP-202602-0027', '1.4', 392.93, 392.93),
  ('REP-202602-0027', '1.5', 226.82, 226.82),
  ('REP-202602-0027', '1.12', 191.68, 191.68),
  ('REP-202602-0028', '1.1', 0.00, 0.00),
  ('REP-202602-0028', '1.2', 635.70, 635.70),
  ('REP-202602-0028', '1.3', 1840.08, 1840.08),
  ('REP-202602-0028', '1.6', 797.37, 797.37),
  ('REP-202602-0029', '1.7', 1819.63, 1819.63),
  ('REP-202602-0030', '1.4', 251.48, 251.48),
  ('REP-202602-0030', '1.5', 145.16, 145.16),
  ('REP-202602-0030', '1.12', 122.67, 122.67),
  ('REP-202602-0031', '1.1', 6568.99, 6568.99),
  ('REP-202602-0031', '1.2', 2496.14, 2496.14),
  ('REP-202602-0031', '1.3', 2890.29, 2890.29),
  ('REP-202602-0031', '1.6', 1252.46, 1252.46),
  ('REP-202602-0032', '1.7', 1714.91, 1714.91),
  ('REP-202602-0033', '1.7', 1143.27, 1143.27),
  ('REP-202602-0034', '1.4', 395.01, 395.01),
  ('REP-202602-0034', '1.5', 228.01, 228.01),
  ('REP-202602-0034', '1.12', 192.69, 192.69),
  ('REP-202602-0034', '1.13', 128.46, 128.46),
  ('REP-202602-0035', '1.1', 3613.90, 3613.90),
  ('REP-202602-0035', '1.2', 989.55, 989.55),
  ('REP-202602-0035', '1.3', 1818.47, 1818.47),
  ('REP-202602-0035', '1.6', 788.00, 788.00),
  ('REP-202602-0036', '1.7', 1078.96, 1078.96),
  ('REP-202602-0037', '1.7', 719.30, 719.30),
  ('REP-202602-0038', '1.4', 248.52, 248.52),
  ('REP-202602-0038', '1.5', 143.46, 143.46),
  ('REP-202602-0038', '1.12', 121.23, 121.23),
  ('REP-202602-0038', '1.13', 80.82, 80.82),
  ('REP-202602-0039', '1.1', 6907.84, 6907.84),
  ('REP-202602-0039', '1.2', 2015.35, 2015.35),
  ('REP-202602-0039', '1.3', 3288.19, 3288.19),
  ('REP-202602-0039', '1.6', 1424.88, 1424.88),
  ('REP-202602-0040', '1.7', 1950.99, 1950.99),
  ('REP-202602-0041', '1.7', 1300.66, 1300.66),
  ('REP-202602-0042', '1.4', 449.39, 449.39),
  ('REP-202602-0042', '1.5', 259.40, 259.40),
  ('REP-202602-0042', '1.12', 219.21, 219.21),
  ('REP-202602-0043', '1.11', 274.02, 274.02);
INSERT INTO RESPALDA (Num_reporte, Cod_obligacion, Monto_adeudado, Monto_pagado_rep) VALUES
  ('REP-202602-0044', '1.1', 1782.14, 1782.14),
  ('REP-202602-0044', '1.2', 844.42, 844.42),
  ('REP-202602-0044', '1.3', 1524.81, 1524.81),
  ('REP-202602-0044', '1.6', 660.75, 660.75),
  ('REP-202602-0045', '1.7', 904.72, 904.72),
  ('REP-202602-0046', '1.7', 603.15, 603.15),
  ('REP-202602-0047', '1.4', 208.39, 208.39),
  ('REP-202602-0047', '1.5', 120.29, 120.29),
  ('REP-202602-0047', '1.12', 101.65, 101.65),
  ('REP-202602-0047', '1.13', 67.77, 67.77),
  ('REP-202602-0048', '1.1', 2776.33, 2776.33),
  ('REP-202602-0048', '1.2', 1380.66, 1380.66),
  ('REP-202602-0048', '1.3', 1625.95, 1625.95),
  ('REP-202602-0048', '1.6', 704.58, 704.58),
  ('REP-202602-0049', '1.7', 964.73, 964.73),
  ('REP-202602-0050', '1.7', 643.16, 643.16),
  ('REP-202602-0051', '1.4', 222.21, 222.21),
  ('REP-202602-0051', '1.5', 128.27, 128.27),
  ('REP-202602-0051', '1.12', 108.40, 108.40),
  ('REP-202602-0052', '1.1', 5873.83, 5873.83),
  ('REP-202602-0052', '1.2', 2277.90, 2277.90),
  ('REP-202602-0052', '1.3', 2782.32, 2782.32),
  ('REP-202602-0052', '1.6', 1205.67, 1205.67),
  ('REP-202602-0053', '1.7', 2751.41, 2751.41),
  ('REP-202602-0054', '1.4', 380.25, 380.25),
  ('REP-202602-0054', '1.5', 219.49, 219.49),
  ('REP-202602-0054', '1.12', 185.49, 185.49),
  ('REP-202602-0055', '1.10', 262.50, 262.50),
  ('REP-202603-0001', '1.1', 1592.33, 1592.33),
  ('REP-202603-0001', '1.2', 988.67, 988.67),
  ('REP-202603-0001', '1.3', 1810.57, 1810.57),
  ('REP-202603-0001', '1.6', 784.58, 784.58),
  ('REP-202603-0002', '1.7', 1074.28, 1074.28),
  ('REP-202603-0003', '1.7', 716.18, 716.18),
  ('REP-202603-0004', '1.4', 247.45, 247.45),
  ('REP-202603-0004', '1.5', 142.83, 142.83),
  ('REP-202603-0004', '1.12', 120.70, 120.70),
  ('REP-202603-0004', '1.13', 80.47, 80.47),
  ('REP-202603-0005', '1.1', 7232.48, 7232.48),
  ('REP-202603-0005', '1.2', 2007.89, 2007.89),
  ('REP-202603-0005', '1.3', 3221.05, 3221.05),
  ('REP-202603-0005', '1.6', 1395.79, 1395.79),
  ('REP-202603-0006', '1.7', 1911.16, 1911.16),
  ('REP-202603-0007', '1.7', 1274.10, 1274.10),
  ('REP-202603-0008', '1.4', 440.21, 440.21),
  ('REP-202603-0008', '1.5', 254.11, 254.11),
  ('REP-202603-0008', '1.12', 214.74, 214.74),
  ('REP-202603-0009', '1.11', 268.42, 268.42),
  ('REP-202603-0010', '1.1', 1852.09, 1852.09),
  ('REP-202603-0010', '1.2', 633.35, 633.35),
  ('REP-202603-0010', '1.3', 1312.66, 1312.66),
  ('REP-202603-0010', '1.6', 568.82, 568.82),
  ('REP-202603-0011', '1.7', 1298.07, 1298.07),
  ('REP-202603-0012', '1.4', 179.40, 179.40),
  ('REP-202603-0012', '1.5', 103.55, 103.55),
  ('REP-202603-0012', '1.12', 87.51, 87.51),
  ('REP-202603-0013', '1.1', 0.00, 0.00),
  ('REP-202603-0013', '1.2', 646.71, 646.71),
  ('REP-202603-0013', '1.3', 1939.18, 1939.18),
  ('REP-202603-0013', '1.6', 840.31, 840.31),
  ('REP-202603-0014', '1.7', 1917.63, 1917.63),
  ('REP-202603-0015', '1.4', 265.02, 265.02),
  ('REP-202603-0015', '1.5', 152.98, 152.98),
  ('REP-202603-0015', '1.12', 129.28, 129.28),
  ('REP-202603-0016', '1.1', 5259.77, 5259.77),
  ('REP-202603-0016', '1.2', 2137.85, 2137.85),
  ('REP-202603-0016', '1.3', 3209.39, 3209.39),
  ('REP-202603-0016', '1.6', 1390.74, 1390.74),
  ('REP-202603-0017', '1.7', 1904.24, 1904.24),
  ('REP-202603-0018', '1.7', 1269.49, 1269.49),
  ('REP-202603-0019', '1.4', 438.62, 438.62),
  ('REP-202603-0019', '1.5', 253.19, 253.19),
  ('REP-202603-0019', '1.12', 213.96, 213.96),
  ('REP-202603-0020', '1.10', 237.50, 237.50),
  ('REP-202603-0021', '1.1', 4778.98, 4778.98),
  ('REP-202603-0021', '1.2', 2505.89, 2505.89),
  ('REP-202603-0021', '1.3', 2978.04, 2978.04),
  ('REP-202603-0021', '1.6', 1290.48, 1290.48),
  ('REP-202603-0022', '1.7', 1766.97, 1766.97),
  ('REP-202603-0023', '1.7', 1177.98, 1177.98),
  ('REP-202603-0024', '1.4', 407.00, 407.00),
  ('REP-202603-0024', '1.5', 234.93, 234.93),
  ('REP-202603-0024', '1.12', 198.54, 198.54),
  ('REP-202603-0024', '1.13', 132.36, 132.36),
  ('REP-202603-0025', '1.1', 4598.50, 4598.50),
  ('REP-202603-0025', '1.2', 1235.95, 1235.95),
  ('REP-202603-0025', '1.3', 1673.57, 1673.57),
  ('REP-202603-0025', '1.6', 725.22, 725.22),
  ('REP-202603-0026', '1.7', 992.99, 992.99),
  ('REP-202603-0027', '1.7', 661.99, 661.99),
  ('REP-202603-0028', '1.4', 228.72, 228.72),
  ('REP-202603-0028', '1.5', 132.03, 132.03),
  ('REP-202603-0028', '1.12', 111.57, 111.57),
  ('REP-202603-0029', '1.1', 4338.37, 4338.37),
  ('REP-202603-0029', '1.2', 1678.89, 1678.89),
  ('REP-202603-0029', '1.3', 2960.01, 2960.01),
  ('REP-202603-0029', '1.6', 1282.67, 1282.67),
  ('REP-202603-0030', '1.7', 2927.12, 2927.12),
  ('REP-202603-0031', '1.4', 404.54, 404.54),
  ('REP-202603-0031', '1.5', 233.51, 233.51);
INSERT INTO RESPALDA (Num_reporte, Cod_obligacion, Monto_adeudado, Monto_pagado_rep) VALUES
  ('REP-202603-0031', '1.12', 197.33, 197.33),
  ('REP-202603-0032', '1.1', 7557.02, 7557.02),
  ('REP-202603-0032', '1.2', 2288.17, 2288.17),
  ('REP-202603-0032', '1.3', 2874.82, 2874.82),
  ('REP-202603-0032', '1.6', 1245.76, 1245.76),
  ('REP-202603-0033', '1.7', 2842.88, 2842.88),
  ('REP-202603-0034', '1.4', 392.89, 392.89),
  ('REP-202603-0034', '1.5', 226.79, 226.79),
  ('REP-202603-0034', '1.12', 191.65, 191.65),
  ('REP-202603-0035', '1.10', 262.50, 262.50),
  ('REP-202603-0036', '1.1', 3059.34, 3059.34),
  ('REP-202603-0036', '1.2', 844.03, 844.03),
  ('REP-202603-0036', '1.3', 1521.31, 1521.31),
  ('REP-202603-0036', '1.6', 659.24, 659.24),
  ('REP-202603-0037', '1.7', 902.65, 902.65),
  ('REP-202603-0038', '1.7', 601.76, 601.76),
  ('REP-202603-0039', '1.4', 207.91, 207.91),
  ('REP-202603-0039', '1.5', 120.01, 120.01),
  ('REP-202603-0039', '1.12', 101.42, 101.42),
  ('REP-202603-0039', '1.13', 67.61, 67.61),
  ('REP-202603-0040', '1.1', 0.00, 0.00),
  ('REP-202603-0040', '1.2', 724.42, 724.42),
  ('REP-202603-0040', '1.3', 1119.82, 1119.82),
  ('REP-202603-0040', '1.6', 485.26, 485.26),
  ('REP-202603-0041', '1.7', 1107.38, 1119.98),
  ('REP-202603-0042', '1.4', 153.04, 153.04),
  ('REP-202603-0042', '1.5', 88.34, 88.34),
  ('REP-202603-0042', '1.12', 74.65, 74.65),
  ('REP-202603-0043', '1.1', 2801.19, 2801.19),
  ('REP-202603-0043', '1.2', 959.13, 959.13),
  ('REP-202603-0043', '1.3', 2219.67, 2219.67),
  ('REP-202603-0043', '1.6', 961.86, 961.86),
  ('REP-202603-0044', '1.7', 2195.01, 2195.01),
  ('REP-202603-0045', '1.4', 303.35, 303.35),
  ('REP-202603-0045', '1.5', 175.11, 175.11),
  ('REP-202603-0045', '1.12', 147.98, 147.98),
  ('REP-202603-0046', '1.1', 2479.15, 2479.15),
  ('REP-202603-0046', '1.2', 1344.48, 1344.48),
  ('REP-202603-0046', '1.3', 2312.80, 2312.80),
  ('REP-202603-0046', '1.6', 1002.21, 1002.21),
  ('REP-202603-0047', '1.7', 1372.26, 1372.26),
  ('REP-202603-0048', '1.7', 914.84, 914.84),
  ('REP-202603-0049', '1.4', 316.08, 316.08),
  ('REP-202603-0049', '1.5', 182.45, 182.45),
  ('REP-202603-0049', '1.12', 154.19, 154.19),
  ('REP-202603-0050', '1.10', 145.00, 145.00),
  ('REP-202603-0051', '1.1', 3905.44, 3905.44),
  ('REP-202603-0051', '1.2', 1390.33, 1390.33),
  ('REP-202603-0051', '1.3', 1713.00, 1713.00),
  ('REP-202603-0051', '1.6', 742.30, 742.30),
  ('REP-202603-0052', '1.7', 1016.38, 1016.38),
  ('REP-202603-0053', '1.7', 677.59, 677.59),
  ('REP-202603-0054', '1.4', 234.11, 234.11),
  ('REP-202603-0054', '1.5', 135.14, 135.14),
  ('REP-202603-0054', '1.12', 114.20, 114.20),
  ('REP-202603-0055', '1.1', 6586.88, 6586.88),
  ('REP-202603-0055', '1.2', 2502.36, 2502.36),
  ('REP-202603-0055', '1.3', 2946.24, 2946.24),
  ('REP-202603-0055', '1.6', 1276.70, 1276.70),
  ('REP-202603-0056', '1.7', 1748.10, 1748.10),
  ('REP-202603-0057', '1.7', 1165.40, 1165.40),
  ('REP-202603-0058', '1.4', 402.65, 402.65),
  ('REP-202603-0058', '1.5', 232.43, 232.43),
  ('REP-202603-0058', '1.12', 196.42, 196.42),
  ('REP-202603-0058', '1.13', 130.94, 130.94),
  ('REP-202604-0001', '1.1', 1455.14, 1455.14),
  ('REP-202604-0001', '1.2', 631.67, 631.67),
  ('REP-202604-0001', '1.3', 1297.51, 1297.51),
  ('REP-202604-0001', '1.6', 562.25, 562.25),
  ('REP-202604-0002', '1.7', 1283.09, 1283.09),
  ('REP-202604-0003', '1.4', 177.33, 177.33),
  ('REP-202604-0003', '1.5', 102.36, 102.36),
  ('REP-202604-0003', '1.12', 86.50, 86.50),
  ('REP-202604-0004', '1.1', 5911.42, 5911.42),
  ('REP-202604-0004', '1.2', 2275.95, 2275.95),
  ('REP-202604-0004', '1.3', 2764.83, 2764.83),
  ('REP-202604-0004', '1.6', 1198.09, 1198.09),
  ('REP-202604-0005', '1.7', 2734.11, 2734.11),
  ('REP-202604-0006', '1.4', 377.86, 377.86),
  ('REP-202604-0006', '1.5', 218.11, 218.11),
  ('REP-202604-0006', '1.12', 184.32, 184.32),
  ('REP-202604-0007', '1.10', 262.50, 262.50),
  ('REP-202604-0008', '1.1', 1601.79, 1601.79),
  ('REP-202604-0008', '1.2', 844.84, 844.84),
  ('REP-202604-0008', '1.3', 1528.57, 1528.57),
  ('REP-202604-0008', '1.6', 662.38, 662.38),
  ('REP-202604-0009', '1.7', 906.95, 906.95),
  ('REP-202604-0010', '1.7', 604.64, 604.64),
  ('REP-202604-0011', '1.4', 208.90, 208.90),
  ('REP-202604-0011', '1.5', 120.59, 120.59),
  ('REP-202604-0011', '1.12', 101.90, 101.90),
  ('REP-202604-0011', '1.13', 67.94, 67.94),
  ('REP-202604-0012', '1.1', 2170.97, 2170.97),
  ('REP-202604-0012', '1.2', 958.26, 958.26),
  ('REP-202604-0012', '1.3', 2211.84, 2211.84),
  ('REP-202604-0012', '1.6', 958.47, 958.47),
  ('REP-202604-0013', '1.7', 2187.27, 2187.27),
  ('REP-202604-0014', '1.4', 302.29, 302.29),
  ('REP-202604-0014', '1.5', 174.49, 174.49),
  ('REP-202604-0014', '1.12', 147.46, 147.46);
INSERT INTO RESPALDA (Num_reporte, Cod_obligacion, Monto_adeudado, Monto_pagado_rep) VALUES
  ('REP-202604-0015', '1.1', 1165.93, 1165.93),
  ('REP-202604-0015', '1.2', 520.45, 520.45),
  ('REP-202604-0015', '1.3', 1646.52, 1646.52),
  ('REP-202604-0015', '1.6', 713.49, 713.49),
  ('REP-202604-0016', '1.7', 1628.22, 1628.22),
  ('REP-202604-0017', '1.4', 225.02, 225.02),
  ('REP-202604-0017', '1.5', 129.89, 129.89),
  ('REP-202604-0017', '1.12', 109.77, 109.77),
  ('REP-202604-0018', '1.1', 0.00, 0.00),
  ('REP-202604-0018', '1.2', 641.71, 641.71),
  ('REP-202604-0018', '1.3', 1894.10, 1894.10),
  ('REP-202604-0018', '1.6', 820.78, 820.78),
  ('REP-202604-0019', '1.7', 1873.06, 1873.06),
  ('REP-202604-0020', '1.4', 258.86, 258.86),
  ('REP-202604-0020', '1.5', 149.42, 149.42),
  ('REP-202604-0020', '1.12', 126.27, 126.27),
  ('REP-202604-0021', '1.1', 3478.11, 3478.11),
  ('REP-202604-0021', '1.2', 1235.58, 1235.58),
  ('REP-202604-0021', '1.3', 1670.26, 1670.26),
  ('REP-202604-0021', '1.6', 723.78, 723.78),
  ('REP-202604-0022', '1.7', 991.03, 991.03),
  ('REP-202604-0023', '1.7', 660.68, 660.68),
  ('REP-202604-0024', '1.4', 228.27, 228.27),
  ('REP-202604-0024', '1.5', 131.77, 131.77),
  ('REP-202604-0024', '1.12', 111.35, 111.35),
  ('REP-202604-0025', '1.1', 0.00, 0.00),
  ('REP-202604-0025', '1.2', 726.94, 726.94),
  ('REP-202604-0025', '1.3', 1142.48, 1142.48),
  ('REP-202604-0025', '1.6', 495.08, 495.08),
  ('REP-202604-0026', '1.7', 1129.79, 1129.79),
  ('REP-202604-0027', '1.4', 156.14, 156.14),
  ('REP-202604-0027', '1.5', 90.13, 90.13),
  ('REP-202604-0027', '1.12', 76.17, 76.17),
  ('REP-202604-0028', '1.1', 2910.15, 2910.15),
  ('REP-202604-0028', '1.2', 1670.36, 1670.36),
  ('REP-202604-0028', '1.3', 2883.25, 2883.25),
  ('REP-202604-0028', '1.6', 1249.41, 1249.41),
  ('REP-202604-0029', '1.7', 2851.22, 2851.22),
  ('REP-202604-0030', '1.4', 394.04, 394.04),
  ('REP-202604-0030', '1.5', 227.46, 227.46),
  ('REP-202604-0030', '1.12', 192.22, 192.22),
  ('REP-202604-0031', '1.1', 2099.78, 2099.78),
  ('REP-202604-0031', '1.2', 991.40, 991.40),
  ('REP-202604-0031', '1.3', 1835.06, 1835.06),
  ('REP-202604-0031', '1.6', 795.19, 795.19),
  ('REP-202604-0032', '1.7', 1088.80, 1088.80),
  ('REP-202604-0033', '1.7', 725.87, 725.87),
  ('REP-202604-0034', '1.4', 250.79, 250.79),
  ('REP-202604-0034', '1.5', 144.77, 144.77),
  ('REP-202604-0034', '1.12', 122.34, 122.34),
  ('REP-202604-0034', '1.13', 81.56, 81.56),
  ('REP-202604-0035', '1.1', 5488.82, 5488.82),
  ('REP-202604-0035', '1.2', 2497.07, 2497.07),
  ('REP-202604-0035', '1.3', 2898.59, 2898.59),
  ('REP-202604-0035', '1.6', 1256.06, 1256.06),
  ('REP-202604-0036', '1.7', 1719.83, 1719.83),
  ('REP-202604-0037', '1.7', 1146.56, 1146.56),
  ('REP-202604-0038', '1.4', 396.14, 396.14),
  ('REP-202604-0038', '1.5', 228.67, 228.67),
  ('REP-202604-0038', '1.12', 193.24, 193.24),
  ('REP-202604-0038', '1.13', 128.83, 128.83),
  ('REP-202604-0039', '1.1', 8226.07, 8226.07),
  ('REP-202604-0039', '1.2', 2120.49, 2120.49),
  ('REP-202604-0039', '1.3', 3053.12, 3053.12),
  ('REP-202604-0039', '1.6', 1323.02, 1323.02),
  ('REP-202604-0040', '1.7', 1811.52, 1811.52),
  ('REP-202604-0041', '1.7', 1207.68, 1207.68),
  ('REP-202604-0042', '1.4', 417.26, 417.26),
  ('REP-202604-0042', '1.5', 240.86, 240.86),
  ('REP-202604-0042', '1.12', 203.54, 203.54),
  ('REP-202604-0043', '1.10', 237.50, 237.50),
  ('REP-202604-0044', '1.1', 2968.21, 2968.21),
  ('REP-202604-0044', '1.2', 1387.11, 1387.11),
  ('REP-202604-0044', '1.3', 1684.02, 1684.02),
  ('REP-202604-0044', '1.6', 729.74, 729.74),
  ('REP-202604-0045', '1.7', 999.19, 999.19),
  ('REP-202604-0046', '1.7', 666.12, 666.12),
  ('REP-202604-0047', '1.4', 230.15, 230.15),
  ('REP-202604-0047', '1.5', 132.85, 132.85),
  ('REP-202604-0047', '1.12', 112.27, 112.27),
  ('REP-202604-0048', '1.1', 5625.67, 5625.67),
  ('REP-202604-0048', '1.2', 2002.66, 2002.66),
  ('REP-202604-0048', '1.3', 3173.90, 3173.90),
  ('REP-202604-0048', '1.6', 1375.36, 1375.36),
  ('REP-202604-0049', '1.7', 1883.18, 1883.18),
  ('REP-202604-0050', '1.7', 1255.46, 1255.46),
  ('REP-202604-0051', '1.4', 433.77, 433.77),
  ('REP-202604-0051', '1.5', 250.39, 250.39),
  ('REP-202604-0051', '1.12', 211.59, 211.59),
  ('REP-202604-0052', '1.11', 264.49, 264.49),
  ('REP-202604-0053', '1.1', 2257.58, 2257.58),
  ('REP-202604-0053', '1.2', 1345.04, 1345.04),
  ('REP-202604-0053', '1.3', 2317.89, 2317.89),
  ('REP-202604-0053', '1.6', 1004.42, 1004.42),
  ('REP-202604-0054', '1.7', 1375.28, 1375.28),
  ('REP-202604-0055', '1.7', 916.86, 916.86),
  ('REP-202604-0056', '1.4', 316.78, 316.78),
  ('REP-202604-0056', '1.5', 182.86, 182.86),
  ('REP-202604-0056', '1.12', 154.53, 154.53),
  ('REP-202604-0057', '1.10', 145.00, 145.00);
INSERT INTO RESPALDA (Num_reporte, Cod_obligacion, Monto_adeudado, Monto_pagado_rep) VALUES
  ('REP-202605-0001', '1.1', 0.00, 0.00),
  ('REP-202605-0001', '1.2', 727.24, 727.24),
  ('REP-202605-0001', '1.3', 1145.18, 1145.18),
  ('REP-202605-0001', '1.6', 496.25, 496.25),
  ('REP-202605-0002', '1.7', 1132.46, 1132.46),
  ('REP-202605-0003', '1.4', 156.51, 156.51),
  ('REP-202605-0003', '1.5', 90.34, 90.34),
  ('REP-202605-0003', '1.12', 76.35, 76.35),
  ('REP-202605-0004', '1.1', 7349.60, 7349.60),
  ('REP-202605-0004', '1.2', 2127.67, 2127.67),
  ('REP-202605-0004', '1.3', 3117.77, 3117.77),
  ('REP-202605-0004', '1.6', 1351.03, 1351.03),
  ('REP-202605-0005', '1.7', 1849.87, 1849.87),
  ('REP-202605-0006', '1.7', 1233.25, 1233.25),
  ('REP-202605-0007', '1.4', 426.09, 426.09),
  ('REP-202605-0007', '1.5', 245.96, 245.96),
  ('REP-202605-0007', '1.12', 207.85, 207.85),
  ('REP-202605-0008', '1.10', 237.50, 237.50),
  ('REP-202605-0009', '1.1', 3049.49, 3049.49),
  ('REP-202605-0009', '1.2', 1382.03, 1382.03),
  ('REP-202605-0009', '1.3', 1638.29, 1638.29),
  ('REP-202605-0009', '1.6', 709.93, 709.93),
  ('REP-202605-0010', '1.7', 972.05, 972.05),
  ('REP-202605-0011', '1.7', 648.04, 648.04),
  ('REP-202605-0012', '1.4', 223.90, 223.90),
  ('REP-202605-0012', '1.5', 129.24, 129.24),
  ('REP-202605-0012', '1.12', 109.22, 109.22),
  ('REP-202605-0013', '1.1', 1579.87, 1579.87),
  ('REP-202605-0013', '1.2', 629.75, 629.75),
  ('REP-202605-0013', '1.3', 1280.27, 1280.27),
  ('REP-202605-0013', '1.6', 554.79, 554.79),
  ('REP-202605-0014', '1.7', 1266.05, 1266.05),
  ('REP-202605-0015', '1.4', 174.97, 174.97),
  ('REP-202605-0015', '1.5', 101.00, 101.00),
  ('REP-202605-0015', '1.12', 85.35, 85.35),
  ('REP-202605-0016', '1.1', 0.00, 0.00),
  ('REP-202605-0016', '1.2', 642.98, 642.98),
  ('REP-202605-0016', '1.3', 1905.58, 1905.58),
  ('REP-202605-0016', '1.6', 825.75, 825.75),
  ('REP-202605-0017', '1.7', 1884.41, 1884.41),
  ('REP-202605-0018', '1.4', 260.43, 260.43),
  ('REP-202605-0018', '1.5', 150.33, 150.33),
  ('REP-202605-0018', '1.12', 127.04, 127.04),
  ('REP-202605-0019', '1.1', 2796.30, 2796.30),
  ('REP-202605-0019', '1.2', 1341.69, 1341.69),
  ('REP-202605-0019', '1.3', 2287.70, 2287.70),
  ('REP-202605-0019', '1.6', 991.33, 991.33),
  ('REP-202605-0020', '1.7', 1357.37, 1357.37),
  ('REP-202605-0021', '1.7', 904.91, 904.91),
  ('REP-202605-0022', '1.4', 312.65, 312.65),
  ('REP-202605-0022', '1.5', 180.47, 180.47),
  ('REP-202605-0022', '1.12', 152.51, 152.51),
  ('REP-202605-0023', '1.10', 145.00, 145.00),
  ('REP-202605-0024', '1.1', 3466.84, 3466.84),
  ('REP-202605-0024', '1.2', 1235.49, 1235.49),
  ('REP-202605-0024', '1.3', 1669.42, 1669.42),
  ('REP-202605-0024', '1.6', 723.42, 723.42),
  ('REP-202605-0025', '1.7', 990.52, 990.52),
  ('REP-202605-0026', '1.7', 660.35, 660.35),
  ('REP-202605-0027', '1.4', 228.15, 228.15),
  ('REP-202605-0027', '1.5', 131.70, 131.70),
  ('REP-202605-0027', '1.12', 111.29, 111.29),
  ('REP-202605-0028', '1.1', 9227.29, 9227.29),
  ('REP-202605-0028', '1.2', 2511.32, 2511.32),
  ('REP-202605-0028', '1.3', 3026.85, 3026.85),
  ('REP-202605-0028', '1.6', 1311.63, 1311.63),
  ('REP-202605-0029', '1.7', 1795.93, 1795.93),
  ('REP-202605-0030', '1.7', 1197.29, 1197.29),
  ('REP-202605-0031', '1.4', 413.67, 413.67),
  ('REP-202605-0031', '1.5', 238.78, 238.78),
  ('REP-202605-0031', '1.12', 201.79, 201.79),
  ('REP-202605-0031', '1.13', 134.53, 134.53),
  ('REP-202605-0032', '1.1', 3587.39, 3587.39),
  ('REP-202605-0032', '1.2', 2012.84, 2012.84),
  ('REP-202605-0032', '1.3', 3265.59, 3265.59),
  ('REP-202605-0032', '1.6', 1415.09, 1415.09),
  ('REP-202605-0033', '1.7', 1937.58, 1937.58),
  ('REP-202605-0034', '1.7', 1291.72, 1291.72),
  ('REP-202605-0035', '1.4', 446.30, 446.30),
  ('REP-202605-0035', '1.5', 257.62, 257.62),
  ('REP-202605-0035', '1.12', 217.71, 217.71),
  ('REP-202605-0036', '1.11', 272.13, 272.13),
  ('REP-202605-0037', '1.1', 1466.45, 1466.45),
  ('REP-202605-0037', '1.2', 841.82, 841.82),
  ('REP-202605-0037', '1.3', 1501.35, 1501.35),
  ('REP-202605-0037', '1.6', 650.59, 650.59),
  ('REP-202605-0038', '1.7', 890.80, 890.80),
  ('REP-202605-0039', '1.7', 593.87, 593.87),
  ('REP-202605-0040', '1.4', 205.18, 205.18),
  ('REP-202605-0040', '1.5', 118.44, 118.44),
  ('REP-202605-0040', '1.12', 100.09, 100.09),
  ('REP-202605-0040', '1.13', 66.73, 66.73),
  ('REP-202605-0041', '1.1', 2779.27, 2779.27),
  ('REP-202605-0041', '1.2', 1099.76, 1099.76),
  ('REP-202605-0041', '1.3', 2472.88, 2472.88),
  ('REP-202605-0041', '1.6', 1071.58, 1071.58),
  ('REP-202605-0042', '1.7', 2445.40, 2445.40),
  ('REP-202605-0043', '1.4', 337.96, 337.96),
  ('REP-202605-0043', '1.5', 195.08, 195.08),
  ('REP-202605-0043', '1.12', 164.86, 164.86);
INSERT INTO RESPALDA (Num_reporte, Cod_obligacion, Monto_adeudado, Monto_pagado_rep) VALUES
  ('REP-202605-0044', '1.1', 2989.84, 2989.84),
  ('REP-202605-0044', '1.2', 952.84, 952.84),
  ('REP-202605-0044', '1.3', 2163.06, 2163.06),
  ('REP-202605-0044', '1.6', 937.33, 944.68),
  ('REP-202605-0045', '1.7', 2139.03, 2139.03),
  ('REP-202605-0046', '1.4', 295.62, 295.62),
  ('REP-202605-0046', '1.5', 170.64, 170.64),
  ('REP-202605-0046', '1.12', 144.20, 144.20),
  ('REP-202605-0047', '1.1', 1248.16, 1248.16),
  ('REP-202605-0047', '1.2', 527.80, 527.80),
  ('REP-202605-0047', '1.3', 1712.66, 1712.66),
  ('REP-202605-0047', '1.6', 742.15, 742.15),
  ('REP-202605-0048', '1.7', 1693.63, 1693.63),
  ('REP-202605-0049', '1.4', 234.06, 234.06),
  ('REP-202605-0049', '1.5', 135.11, 135.11),
  ('REP-202605-0049', '1.12', 114.18, 114.18),
  ('REP-202605-0050', '1.1', 1915.78, 1915.78),
  ('REP-202605-0050', '1.2', 992.37, 992.37),
  ('REP-202605-0050', '1.3', 1843.83, 1843.83),
  ('REP-202605-0050', '1.6', 798.99, 798.99),
  ('REP-202605-0051', '1.7', 1094.00, 1094.00),
  ('REP-202605-0052', '1.7', 729.34, 729.34),
  ('REP-202605-0053', '1.4', 251.99, 251.99),
  ('REP-202605-0053', '1.5', 145.46, 145.46),
  ('REP-202605-0053', '1.12', 122.92, 122.92),
  ('REP-202605-0053', '1.13', 81.95, 81.95),
  ('REP-202605-0054', '1.1', 0.00, 0.00),
  ('REP-202605-0054', '1.2', 635.64, 635.64),
  ('REP-202605-0054', '1.3', 1839.47, 1839.47),
  ('REP-202605-0054', '1.6', 797.10, 797.10),
  ('REP-202605-0055', '1.7', 1819.03, 1819.03),
  ('REP-202605-0056', '1.4', 251.39, 251.39),
  ('REP-202605-0056', '1.5', 145.11, 145.11),
  ('REP-202605-0056', '1.12', 122.63, 122.63),
  ('REP-202605-0057', '1.1', 5864.65, 5864.65),
  ('REP-202605-0057', '1.2', 1663.15, 1663.15),
  ('REP-202605-0057', '1.3', 2818.35, 2818.35),
  ('REP-202605-0057', '1.6', 1221.29, 1221.29),
  ('REP-202605-0058', '1.7', 2787.04, 2787.04),
  ('REP-202605-0059', '1.4', 385.17, 385.17),
  ('REP-202605-0059', '1.5', 222.34, 222.34),
  ('REP-202605-0059', '1.12', 187.89, 187.89),
  ('REP-202605-0060', '1.1', 7087.66, 7087.66),
  ('REP-202605-0060', '1.2', 2277.26, 2277.26),
  ('REP-202605-0060', '1.3', 2776.55, 2776.55),
  ('REP-202605-0060', '1.6', 1203.17, 1203.17),
  ('REP-202605-0061', '1.7', 2745.70, 2745.70),
  ('REP-202605-0062', '1.4', 379.46, 379.46),
  ('REP-202605-0062', '1.5', 219.04, 219.04),
  ('REP-202605-0062', '1.12', 185.10, 185.10),
  ('REP-202605-0063', '1.10', 262.50, 262.50),
  ('REP-202606-0001', '1.1', 0.00, 0.00),
  ('REP-202606-0001', '1.2', 724.88, 724.88),
  ('REP-202606-0001', '1.3', 1123.94, 1123.94),
  ('REP-202606-0001', '1.6', 487.04, 487.04),
  ('REP-202606-0002', '1.7', 1111.45, 1111.45),
  ('REP-202606-0003', '1.4', 153.61, 153.61),
  ('REP-202606-0003', '1.5', 88.67, 88.67),
  ('REP-202606-0003', '1.12', 74.93, 74.93),
  ('REP-202606-0004', '1.1', 3189.87, 3189.87),
  ('REP-202606-0004', '1.2', 1386.76, 1386.76),
  ('REP-202606-0004', '1.3', 1680.82, 1680.82),
  ('REP-202606-0004', '1.6', 728.36, 728.36),
  ('REP-202606-0005', '1.7', 997.29, 997.29),
  ('REP-202606-0006', '1.7', 664.86, 664.86),
  ('REP-202606-0007', '1.4', 229.71, 229.71),
  ('REP-202606-0007', '1.5', 132.60, 132.60),
  ('REP-202606-0007', '1.12', 112.05, 112.05),
  ('REP-202606-0008', '1.1', 6442.10, 6442.10),
  ('REP-202606-0008', '1.2', 2129.31, 2129.31),
  ('REP-202606-0008', '1.3', 3132.57, 3132.57),
  ('REP-202606-0008', '1.6', 1357.45, 1357.45),
  ('REP-202606-0009', '1.7', 1858.66, 1858.66),
  ('REP-202606-0010', '1.7', 1239.10, 1239.10),
  ('REP-202606-0011', '1.4', 428.12, 428.12),
  ('REP-202606-0011', '1.5', 247.12, 247.12),
  ('REP-202606-0011', '1.12', 208.84, 208.84),
  ('REP-202606-0012', '1.10', 237.50, 237.50),
  ('REP-202606-0013', '1.1', 2733.30, 2733.30),
  ('REP-202606-0013', '1.2', 1094.46, 1094.46),
  ('REP-202606-0013', '1.3', 2425.12, 2425.12),
  ('REP-202606-0013', '1.6', 1050.89, 1050.89),
  ('REP-202606-0014', '1.7', 2398.17, 2398.17),
  ('REP-202606-0015', '1.4', 331.43, 331.43),
  ('REP-202606-0015', '1.5', 191.31, 191.31),
  ('REP-202606-0015', '1.12', 161.67, 161.67),
  ('REP-202606-0016', '1.1', 7789.67, 7789.67),
  ('REP-202606-0016', '1.2', 2507.16, 2507.16),
  ('REP-202606-0016', '1.3', 2989.47, 2989.47),
  ('REP-202606-0016', '1.6', 1295.44, 1295.44),
  ('REP-202606-0017', '1.7', 1773.75, 1773.75),
  ('REP-202606-0018', '1.7', 1182.50, 1182.50),
  ('REP-202606-0019', '1.4', 408.56, 408.56),
  ('REP-202606-0019', '1.5', 235.84, 235.84),
  ('REP-202606-0019', '1.12', 199.30, 199.30),
  ('REP-202606-0019', '1.13', 132.87, 132.87),
  ('REP-202606-0020', '1.1', 2735.56, 2735.56),
  ('REP-202606-0020', '1.2', 1664.09, 1664.09),
  ('REP-202606-0020', '1.3', 2826.77, 2826.77),
  ('REP-202606-0020', '1.6', 1224.94, 1224.94);
INSERT INTO RESPALDA (Num_reporte, Cod_obligacion, Monto_adeudado, Monto_pagado_rep) VALUES
  ('REP-202606-0021', '1.7', 2795.37, 2795.37),
  ('REP-202606-0022', '1.4', 386.33, 386.33),
  ('REP-202606-0022', '1.5', 223.00, 223.00),
  ('REP-202606-0022', '1.12', 188.45, 188.45),
  ('REP-202606-0023', '1.1', 2402.45, 2402.45),
  ('REP-202606-0023', '1.2', 990.43, 990.43),
  ('REP-202606-0023', '1.3', 1826.36, 1826.36),
  ('REP-202606-0023', '1.6', 791.42, 791.42),
  ('REP-202606-0024', '1.7', 1083.64, 1083.64),
  ('REP-202606-0025', '1.7', 722.43, 722.43),
  ('REP-202606-0026', '1.4', 249.60, 249.60),
  ('REP-202606-0026', '1.5', 144.08, 144.08),
  ('REP-202606-0026', '1.12', 121.76, 121.76),
  ('REP-202606-0026', '1.13', 81.17, 81.17),
  ('REP-202606-0027', '1.1', 6483.21, 6483.21),
  ('REP-202606-0027', '1.2', 2276.03, 2276.03),
  ('REP-202606-0027', '1.3', 2765.55, 2765.55),
  ('REP-202606-0027', '1.6', 1198.41, 1198.41),
  ('REP-202606-0028', '1.7', 2734.83, 2734.83),
  ('REP-202606-0029', '1.4', 377.96, 377.96),
  ('REP-202606-0029', '1.5', 218.17, 218.17),
  ('REP-202606-0029', '1.12', 184.37, 184.37),
  ('REP-202606-0030', '1.10', 262.50, 262.50),
  ('REP-202606-0031', '1.1', 3140.63, 3140.63),
  ('REP-202606-0031', '1.2', 955.45, 955.45),
  ('REP-202606-0031', '1.3', 2186.51, 2186.51),
  ('REP-202606-0031', '1.6', 947.49, 947.49),
  ('REP-202606-0032', '1.7', 2162.22, 2162.22),
  ('REP-202606-0033', '1.4', 298.82, 298.82),
  ('REP-202606-0033', '1.5', 172.49, 172.49),
  ('REP-202606-0033', '1.12', 145.77, 145.77),
  ('REP-202606-0034', '1.1', 0.00, 0.00),
  ('REP-202606-0034', '1.2', 642.78, 642.78),
  ('REP-202606-0034', '1.3', 1903.75, 1903.75),
  ('REP-202606-0034', '1.6', 824.96, 824.96),
  ('REP-202606-0035', '1.7', 1882.59, 1882.59),
  ('REP-202606-0036', '1.4', 260.18, 260.18),
  ('REP-202606-0036', '1.5', 150.18, 150.18),
  ('REP-202606-0036', '1.12', 126.92, 126.92),
  ('REP-202606-0037', '1.1', 770.73, 770.73),
  ('REP-202606-0037', '1.2', 524.07, 524.07),
  ('REP-202606-0037', '1.3', 1679.16, 1679.16),
  ('REP-202606-0037', '1.6', 727.64, 727.64),
  ('REP-202606-0038', '1.7', 1660.50, 1660.50),
  ('REP-202606-0039', '1.4', 229.49, 229.49),
  ('REP-202606-0039', '1.5', 132.47, 132.47),
  ('REP-202606-0039', '1.12', 111.94, 111.94),
  ('REP-202606-0040', '1.1', 2912.03, 2912.03),
  ('REP-202606-0040', '1.2', 845.74, 845.74),
  ('REP-202606-0040', '1.3', 1536.62, 1536.62),
  ('REP-202606-0040', '1.6', 665.87, 665.87),
  ('REP-202606-0041', '1.7', 911.72, 911.72),
  ('REP-202606-0042', '1.7', 607.82, 607.82),
  ('REP-202606-0043', '1.4', 210.00, 210.00),
  ('REP-202606-0043', '1.5', 121.22, 121.22),
  ('REP-202606-0043', '1.12', 102.44, 102.44),
  ('REP-202606-0043', '1.13', 68.29, 68.29),
  ('REP-202606-0044', '1.1', 3504.82, 3504.82),
  ('REP-202606-0044', '1.2', 1236.73, 1236.73),
  ('REP-202606-0044', '1.3', 1680.58, 1680.58),
  ('REP-202606-0044', '1.6', 728.25, 728.25),
  ('REP-202606-0045', '1.7', 997.15, 997.15),
  ('REP-202606-0046', '1.7', 664.76, 664.76),
  ('REP-202606-0047', '1.4', 229.68, 229.68),
  ('REP-202606-0047', '1.5', 132.58, 132.58),
  ('REP-202606-0047', '1.12', 112.04, 112.04),
  ('REP-202606-0048', '1.1', 6197.73, 6197.73),
  ('REP-202606-0048', '1.2', 2011.71, 2011.71),
  ('REP-202606-0048', '1.3', 3255.40, 3255.40),
  ('REP-202606-0048', '1.6', 1410.67, 1410.67),
  ('REP-202606-0049', '1.7', 1931.54, 1931.54),
  ('REP-202606-0050', '1.7', 1287.69, 1287.69),
  ('REP-202606-0051', '1.4', 444.90, 444.90),
  ('REP-202606-0051', '1.5', 256.81, 256.81),
  ('REP-202606-0051', '1.12', 217.03, 217.03),
  ('REP-202606-0052', '1.11', 271.28, 271.28),
  ('REP-202606-0053', '1.1', 1982.89, 1982.89),
  ('REP-202606-0053', '1.2', 633.38, 633.38),
  ('REP-202606-0053', '1.3', 1312.93, 1312.93),
  ('REP-202606-0053', '1.6', 568.93, 568.93),
  ('REP-202606-0054', '1.7', 1298.34, 1298.34),
  ('REP-202606-0055', '1.4', 179.43, 179.43),
  ('REP-202606-0055', '1.5', 103.58, 103.58),
  ('REP-202606-0055', '1.12', 87.53, 87.53),
  ('REP-202606-0056', '1.1', 2452.88, 2452.88),
  ('REP-202606-0056', '1.2', 1348.63, 1348.63),
  ('REP-202606-0056', '1.3', 2350.20, 2350.20),
  ('REP-202606-0056', '1.6', 1018.42, 1018.42),
  ('REP-202606-0057', '1.7', 1394.45, 1394.45),
  ('REP-202606-0058', '1.7', 929.64, 929.64),
  ('REP-202606-0059', '1.4', 321.19, 321.19),
  ('REP-202606-0059', '1.5', 185.40, 185.40),
  ('REP-202606-0059', '1.12', 156.68, 156.68),
  ('REP-202606-0060', '1.10', 145.00, 145.00),
  ('REP-202607-0001', '1.1', 6924.60, 6924.60),
  ('REP-202607-0001', '1.2', 2510.18, 2510.18),
  ('REP-202607-0001', '1.3', 3016.60, 3016.60),
  ('REP-202607-0001', '1.6', 1307.19, 1307.19),
  ('REP-202607-0002', '1.7', 1789.85, 1789.85),
  ('REP-202607-0003', '1.7', 1193.23, 1193.23);
INSERT INTO RESPALDA (Num_reporte, Cod_obligacion, Monto_adeudado, Monto_pagado_rep) VALUES
  ('REP-202607-0004', '1.4', 412.27, 412.27),
  ('REP-202607-0004', '1.5', 237.98, 237.98),
  ('REP-202607-0004', '1.12', 201.11, 201.11),
  ('REP-202607-0004', '1.13', 134.07, 134.07),
  ('REP-202607-0005', '1.1', 3597.05, 3597.05),
  ('REP-202607-0005', '1.2', 1087.03, 1087.03),
  ('REP-202607-0005', '1.3', 2358.31, 2358.31),
  ('REP-202607-0005', '1.6', 1021.93, 1021.93),
  ('REP-202607-0006', '1.7', 2332.10, 2332.10),
  ('REP-202607-0007', '1.4', 322.30, 322.30),
  ('REP-202607-0007', '1.5', 186.04, 186.04),
  ('REP-202607-0007', '1.12', 157.22, 157.22),
  ('REP-202607-0008', '1.1', 0.00, 0.00),
  ('REP-202607-0008', '1.2', 727.15, 727.15),
  ('REP-202607-0008', '1.3', 1144.36, 1144.36),
  ('REP-202607-0008', '1.6', 495.89, 495.89),
  ('REP-202607-0009', '1.7', 1131.65, 1131.65),
  ('REP-202607-0010', '1.4', 156.40, 156.40),
  ('REP-202607-0010', '1.5', 90.28, 90.28),
  ('REP-202607-0010', '1.12', 76.29, 76.29),
  ('REP-202607-0011', '1.1', 4935.37, 4935.37),
  ('REP-202607-0011', '1.2', 2289.92, 2289.92),
  ('REP-202607-0011', '1.3', 2890.52, 2890.52),
  ('REP-202607-0011', '1.6', 1252.56, 1252.56),
  ('REP-202607-0012', '1.7', 2858.41, 2858.41),
  ('REP-202607-0013', '1.4', 395.04, 395.04),
  ('REP-202607-0013', '1.5', 228.03, 228.03),
  ('REP-202607-0013', '1.12', 192.70, 192.70),
  ('REP-202607-0014', '1.10', 262.50, 262.50),
  ('REP-202607-0015', '1.1', 3320.55, 3320.55),
  ('REP-202607-0015', '1.2', 2014.33, 2014.33),
  ('REP-202607-0015', '1.3', 3279.00, 3279.00),
  ('REP-202607-0015', '1.6', 1420.90, 1420.90),
  ('REP-202607-0016', '1.7', 1945.54, 1945.54),
  ('REP-202607-0017', '1.7', 1297.03, 1297.03),
  ('REP-202607-0018', '1.4', 448.13, 448.13),
  ('REP-202607-0018', '1.5', 258.68, 258.68),
  ('REP-202607-0018', '1.12', 218.60, 218.60),
  ('REP-202607-0019', '1.11', 273.25, 273.25),
  ('REP-202607-0020', '1.1', 2142.35, 2142.35),
  ('REP-202607-0020', '1.2', 842.57, 842.57),
  ('REP-202607-0020', '1.3', 1508.17, 1508.17),
  ('REP-202607-0020', '1.6', 653.54, 653.54),
  ('REP-202607-0021', '1.7', 894.85, 894.85),
  ('REP-202607-0022', '1.7', 596.57, 596.57),
  ('REP-202607-0023', '1.4', 206.12, 206.12),
  ('REP-202607-0023', '1.5', 118.98, 118.98),
  ('REP-202607-0023', '1.12', 100.54, 100.54),
  ('REP-202607-0023', '1.13', 67.03, 67.03),
  ('REP-202607-0024', '1.1', 7716.38, 7716.38),
  ('REP-202607-0024', '1.2', 2119.93, 2119.93),
  ('REP-202607-0024', '1.3', 3048.13, 3048.13),
  ('REP-202607-0024', '1.6', 1320.86, 1320.86),
  ('REP-202607-0025', '1.7', 1808.56, 1808.56),
  ('REP-202607-0026', '1.7', 1205.71, 1205.71),
  ('REP-202607-0027', '1.4', 416.58, 416.58),
  ('REP-202607-0027', '1.5', 240.46, 240.46),
  ('REP-202607-0027', '1.12', 203.21, 203.21),
  ('REP-202607-0028', '1.10', 237.50, 237.50),
  ('REP-202607-0029', '1.1', 5329.05, 5329.05),
  ('REP-202607-0029', '1.2', 1385.39, 1385.39),
  ('REP-202607-0029', '1.3', 1668.48, 1668.48),
  ('REP-202607-0029', '1.6', 723.01, 723.01),
  ('REP-202607-0030', '1.7', 989.97, 989.97),
  ('REP-202607-0031', '1.7', 659.98, 659.98),
  ('REP-202607-0032', '1.4', 228.03, 228.03),
  ('REP-202607-0032', '1.5', 131.62, 131.62),
  ('REP-202607-0032', '1.12', 111.23, 111.23),
  ('REP-202607-0033', '1.1', 5472.54, 5472.54),
  ('REP-202607-0033', '1.2', 1673.02, 1673.02),
  ('REP-202607-0033', '1.3', 2907.21, 2907.21),
  ('REP-202607-0033', '1.6', 1259.79, 1259.79),
  ('REP-202607-0034', '1.7', 2874.91, 2874.91),
  ('REP-202607-0035', '1.4', 397.32, 397.32),
  ('REP-202607-0035', '1.5', 229.35, 229.35),
  ('REP-202607-0035', '1.12', 193.81, 193.81),
  ('REP-202607-0036', '1.1', 1408.97, 1408.97),
  ('REP-202607-0036', '1.2', 628.10, 628.10),
  ('REP-202607-0036', '1.3', 1265.40, 1265.40),
  ('REP-202607-0036', '1.6', 548.34, 548.34),
  ('REP-202607-0037', '1.7', 1251.34, 1251.34),
  ('REP-202607-0038', '1.4', 172.94, 172.94),
  ('REP-202607-0038', '1.5', 99.83, 99.83),
  ('REP-202607-0038', '1.12', 84.36, 84.36),
  ('REP-202607-0039', '1.1', 0.00, 0.00),
  ('REP-202607-0039', '1.2', 644.63, 644.63),
  ('REP-202607-0039', '1.3', 1920.44, 1920.44),
  ('REP-202607-0039', '1.6', 832.19, 832.19),
  ('REP-202607-0040', '1.7', 1899.10, 1899.10),
  ('REP-202607-0041', '1.4', 262.46, 262.46),
  ('REP-202607-0041', '1.5', 151.50, 151.50),
  ('REP-202607-0041', '1.12', 128.03, 128.03),
  ('REP-202607-0042', '1.1', 2127.39, 2127.39),
  ('REP-202607-0042', '1.2', 1240.60, 1240.60),
  ('REP-202607-0042', '1.3', 1715.38, 1715.38),
  ('REP-202607-0042', '1.6', 743.33, 743.33),
  ('REP-202607-0043', '1.7', 1017.79, 1017.79),
  ('REP-202607-0044', '1.7', 678.53, 678.53),
  ('REP-202607-0045', '1.4', 234.44, 234.44),
  ('REP-202607-0045', '1.5', 135.32, 135.32);
INSERT INTO RESPALDA (Num_reporte, Cod_obligacion, Monto_adeudado, Monto_pagado_rep) VALUES
  ('REP-202607-0045', '1.12', 114.36, 119.76),
  ('REP-202607-0046', '1.1', 2062.12, 2062.12),
  ('REP-202607-0046', '1.2', 956.24, 956.24),
  ('REP-202607-0046', '1.3', 2193.64, 2193.64),
  ('REP-202607-0046', '1.6', 950.58, 950.58),
  ('REP-202607-0047', '1.7', 2169.27, 2169.27),
  ('REP-202607-0048', '1.4', 299.80, 299.80),
  ('REP-202607-0048', '1.5', 173.05, 173.05),
  ('REP-202607-0048', '1.12', 146.24, 146.24),
  ('REP-202607-0049', '1.1', 2472.77, 2472.77),
  ('REP-202607-0049', '1.2', 994.32, 994.32),
  ('REP-202607-0049', '1.3', 1861.37, 1861.37),
  ('REP-202607-0049', '1.6', 806.59, 806.59),
  ('REP-202607-0050', '1.7', 1104.41, 1115.34),
  ('REP-202607-0051', '1.7', 736.28, 743.56),
  ('REP-202607-0052', '1.4', 254.39, 254.39),
  ('REP-202607-0052', '1.5', 146.84, 146.84),
  ('REP-202607-0052', '1.12', 124.09, 124.09),
  ('REP-202607-0052', '1.13', 82.73, 82.73),
  ('REP-202607-0053', '1.1', 1465.12, 1465.12),
  ('REP-202607-0053', '1.2', 527.83, 527.83),
  ('REP-202607-0053', '1.3', 1713.00, 1713.00),
  ('REP-202607-0053', '1.6', 742.30, 742.30),
  ('REP-202607-0054', '1.7', 1693.96, 1693.96),
  ('REP-202607-0055', '1.4', 234.11, 234.11),
  ('REP-202607-0055', '1.5', 135.14, 135.14),
  ('REP-202607-0055', '1.12', 114.20, 114.20),
  ('REP-202607-0056', '1.1', 3902.37, 3902.37),
  ('REP-202607-0056', '1.2', 1338.27, 1338.27),
  ('REP-202607-0056', '1.3', 2256.95, 2270.95),
  ('REP-202607-0056', '1.6', 978.01, 978.01),
  ('REP-202607-0057', '1.7', 1339.12, 1339.12),
  ('REP-202607-0058', '1.7', 892.75, 892.75),
  ('REP-202607-0059', '1.4', 308.45, 308.45),
  ('REP-202607-0059', '1.5', 178.05, 178.05),
  ('REP-202607-0059', '1.12', 150.46, 150.46),
  ('REP-202607-0060', '1.10', 145.00, 145.00),
  ('REP-202608-0001', '1.1', 0.00, 0.00),
  ('REP-202608-0001', '1.2', 644.08, 644.08),
  ('REP-202608-0001', '1.3', 1915.43, 1915.43),
  ('REP-202608-0001', '1.6', 830.02, 830.02),
  ('REP-202608-0002', '1.7', 1894.15, 1894.15),
  ('REP-202608-0003', '1.4', 261.78, 261.78),
  ('REP-202608-0003', '1.5', 151.11, 151.11),
  ('REP-202608-0003', '1.12', 127.70, 127.70),
  ('REP-202608-0004', '1.1', 3299.12, 3299.12),
  ('REP-202608-0004', '1.2', 1343.33, 1343.33),
  ('REP-202608-0004', '1.3', 2302.44, 2302.44),
  ('REP-202608-0004', '1.6', 997.72, 997.72),
  ('REP-202608-0005', '1.7', 1366.12, 1366.12),
  ('REP-202608-0006', '1.7', 910.74, 910.74),
  ('REP-202608-0007', '1.4', 314.67, 314.67),
  ('REP-202608-0007', '1.5', 181.64, 181.64),
  ('REP-202608-0007', '1.12', 153.50, 153.50),
  ('REP-202608-0008', '1.10', 145.00, 145.00),
  ('REP-202608-0009', '1.1', 2045.78, 2045.78),
  ('REP-202608-0009', '1.2', 847.99, 847.99),
  ('REP-202608-0009', '1.3', 1556.95, 1556.95),
  ('REP-202608-0009', '1.6', 674.68, 674.68),
  ('REP-202608-0010', '1.7', 923.79, 923.79),
  ('REP-202608-0011', '1.7', 615.86, 615.86),
  ('REP-202608-0012', '1.4', 212.78, 212.78),
  ('REP-202608-0012', '1.5', 122.83, 122.83),
  ('REP-202608-0012', '1.12', 103.80, 103.80),
  ('REP-202608-0012', '1.13', 69.20, 69.20),
  ('REP-202608-0013', '1.1', 6528.09, 6528.09),
  ('REP-202608-0013', '1.2', 2130.74, 2130.74),
  ('REP-202608-0013', '1.3', 3145.45, 3145.45),
  ('REP-202608-0013', '1.6', 1363.03, 1363.03),
  ('REP-202608-0014', '1.7', 1866.30, 1866.30),
  ('REP-202608-0015', '1.7', 1244.20, 1244.20),
  ('REP-202608-0016', '1.4', 429.88, 429.88),
  ('REP-202608-0016', '1.5', 248.14, 248.14),
  ('REP-202608-0016', '1.12', 209.70, 209.70),
  ('REP-202608-0017', '1.10', 237.50, 237.50),
  ('REP-202608-0018', '1.1', 2718.70, 2718.70),
  ('REP-202608-0018', '1.2', 958.65, 958.65),
  ('REP-202608-0018', '1.3', 2215.39, 2215.39),
  ('REP-202608-0018', '1.6', 960.00, 960.00),
  ('REP-202608-0019', '1.7', 2190.77, 2190.77),
  ('REP-202608-0020', '1.4', 302.77, 302.77),
  ('REP-202608-0020', '1.5', 174.77, 174.77),
  ('REP-202608-0020', '1.12', 147.69, 147.69),
  ('REP-202608-0021', '1.1', 2731.55, 2731.55),
  ('REP-202608-0021', '1.2', 1234.10, 1234.10),
  ('REP-202608-0021', '1.3', 1656.90, 1656.90),
  ('REP-202608-0021', '1.6', 717.99, 717.99),
  ('REP-202608-0022', '1.7', 983.09, 983.09),
  ('REP-202608-0023', '1.7', 655.40, 655.40),
  ('REP-202608-0024', '1.4', 226.44, 226.44),
  ('REP-202608-0024', '1.5', 130.71, 130.71),
  ('REP-202608-0024', '1.12', 110.46, 110.46),
  ('REP-202608-0025', '1.1', 0.00, 0.00),
  ('REP-202608-0025', '1.2', 731.21, 731.21),
  ('REP-202608-0025', '1.3', 1180.92, 1180.92),
  ('REP-202608-0025', '1.6', 511.73, 511.73),
  ('REP-202608-0026', '1.7', 1167.80, 1167.80),
  ('REP-202608-0027', '1.4', 161.39, 161.39),
  ('REP-202608-0027', '1.5', 93.16, 93.16),
  ('REP-202608-0027', '1.12', 78.73, 78.73);
INSERT INTO RESPALDA (Num_reporte, Cod_obligacion, Monto_adeudado, Monto_pagado_rep) VALUES
  ('REP-202608-0028', '1.1', 7084.93, 7084.93),
  ('REP-202608-0028', '1.2', 2283.07, 2283.07),
  ('REP-202608-0028', '1.3', 2828.88, 2828.88),
  ('REP-202608-0028', '1.6', 1225.85, 1225.85),
  ('REP-202608-0029', '1.7', 2797.45, 2797.45),
  ('REP-202608-0030', '1.4', 386.61, 386.61),
  ('REP-202608-0030', '1.5', 223.17, 223.17),
  ('REP-202608-0030', '1.12', 188.59, 188.59),
  ('REP-202608-0031', '1.10', 262.50, 262.50),
  ('REP-202608-0032', '1.1', 7041.02, 7041.02),
  ('REP-202608-0032', '1.2', 2502.91, 2502.91),
  ('REP-202608-0032', '1.3', 2951.22, 2951.22),
  ('REP-202608-0032', '1.6', 1278.86, 1278.86),
  ('REP-202608-0033', '1.7', 1751.05, 1751.05),
  ('REP-202608-0034', '1.7', 1167.37, 1167.37),
  ('REP-202608-0035', '1.4', 403.33, 403.33),
  ('REP-202608-0035', '1.5', 232.82, 232.82),
  ('REP-202608-0035', '1.12', 196.75, 196.75),
  ('REP-202608-0035', '1.13', 131.17, 131.17),
  ('REP-202608-0036', '1.1', 4825.72, 4825.72),
  ('REP-202608-0036', '1.2', 1670.46, 1670.46),
  ('REP-202608-0036', '1.3', 2884.12, 2884.12),
  ('REP-202608-0036', '1.6', 1249.78, 1249.78),
  ('REP-202608-0037', '1.7', 2852.07, 2852.07),
  ('REP-202608-0038', '1.4', 394.16, 394.16),
  ('REP-202608-0038', '1.5', 227.52, 227.52),
  ('REP-202608-0038', '1.12', 192.27, 192.27),
  ('REP-202608-0039', '1.1', 3733.88, 3733.88),
  ('REP-202608-0039', '1.2', 1086.95, 1086.95),
  ('REP-202608-0039', '1.3', 2357.54, 2357.54),
  ('REP-202608-0039', '1.6', 1021.60, 1021.60),
  ('REP-202608-0040', '1.7', 2331.35, 2331.35),
  ('REP-202608-0041', '1.4', 322.20, 322.20),
  ('REP-202608-0041', '1.5', 185.98, 185.98),
  ('REP-202608-0041', '1.12', 157.17, 157.17),
  ('REP-202608-0042', '1.1', 6655.69, 6655.69),
  ('REP-202608-0042', '1.2', 2005.01, 2005.01),
  ('REP-202608-0042', '1.3', 3195.09, 3195.09),
  ('REP-202608-0042', '1.6', 1384.54, 1384.54),
  ('REP-202608-0043', '1.7', 1895.75, 1895.75),
  ('REP-202608-0044', '1.7', 1263.84, 1263.84),
  ('REP-202608-0045', '1.4', 436.66, 436.66),
  ('REP-202608-0045', '1.5', 252.06, 252.06),
  ('REP-202608-0045', '1.12', 213.01, 213.01),
  ('REP-202608-0046', '1.11', 266.26, 266.26),
  ('REP-202608-0047', '1.1', 1987.11, 1987.11),
  ('REP-202608-0047', '1.2', 633.39, 633.39),
  ('REP-202608-0047', '1.3', 1313.03, 1313.03),
  ('REP-202608-0047', '1.6', 568.98, 568.98),
  ('REP-202608-0048', '1.7', 1298.44, 1298.44),
  ('REP-202608-0049', '1.4', 179.45, 179.45),
  ('REP-202608-0049', '1.5', 103.58, 103.58),
  ('REP-202608-0049', '1.12', 87.54, 87.54),
  ('REP-202608-0050', '1.1', 4435.19, 4466.69),
  ('REP-202608-0050', '1.2', 1390.18, 1390.18),
  ('REP-202608-0050', '1.3', 1711.58, 1711.58),
  ('REP-202608-0050', '1.6', 741.69, 741.69),
  ('REP-202608-0051', '1.7', 1015.54, 1015.54),
  ('REP-202608-0052', '1.7', 677.03, 677.03),
  ('REP-202608-0053', '1.4', 233.92, 233.92),
  ('REP-202608-0053', '1.5', 135.02, 135.02),
  ('REP-202608-0053', '1.12', 114.11, 114.11),
  ('REP-202608-0054', '1.1', 2524.13, 2524.13),
  ('REP-202608-0054', '1.2', 992.79, 992.79),
  ('REP-202608-0054', '1.3', 1847.61, 1847.61),
  ('REP-202608-0054', '1.6', 800.63, 800.63),
  ('REP-202608-0055', '1.7', 1096.25, 1096.25),
  ('REP-202608-0056', '1.7', 730.83, 730.83),
  ('REP-202608-0057', '1.4', 252.51, 252.51),
  ('REP-202608-0057', '1.5', 145.76, 145.76),
  ('REP-202608-0057', '1.12', 123.17, 123.17),
  ('REP-202608-0057', '1.13', 82.12, 82.12),
  ('REP-202608-0058', '1.1', 1193.06, 1193.06),
  ('REP-202608-0058', '1.2', 527.67, 527.67),
  ('REP-202608-0058', '1.3', 1711.57, 1711.57),
  ('REP-202608-0058', '1.6', 741.68, 741.68),
  ('REP-202608-0059', '1.7', 1692.56, 1692.56),
  ('REP-202608-0060', '1.4', 233.91, 233.91),
  ('REP-202608-0060', '1.5', 135.02, 135.02),
  ('REP-202608-0060', '1.12', 114.10, 114.10),
  ('REP-202609-0001', '1.1', 1538.30, 1538.30),
  ('REP-202609-0001', '1.2', 844.36, 844.36),
  ('REP-202609-0001', '1.3', 1524.24, 1524.24),
  ('REP-202609-0001', '1.6', 660.50, 660.50),
  ('REP-202609-0002', '1.7', 904.38, 904.38),
  ('REP-202609-0003', '1.7', 602.92, 602.92),
  ('REP-202609-0004', '1.4', 208.31, 208.31),
  ('REP-202609-0004', '1.5', 120.25, 120.25),
  ('REP-202609-0004', '1.12', 101.62, 101.62),
  ('REP-202609-0004', '1.13', 67.74, 67.74),
  ('REP-202609-0005', '1.1', 0.00, 0.00),
  ('REP-202609-0005', '1.2', 727.32, 727.32),
  ('REP-202609-0005', '1.3', 1145.87, 1145.87),
  ('REP-202609-0005', '1.6', 496.54, 496.54),
  ('REP-202609-0006', '1.7', 1133.14, 1133.14),
  ('REP-202609-0007', '1.4', 156.60, 156.60),
  ('REP-202609-0007', '1.5', 90.40, 90.40),
  ('REP-202609-0007', '1.12', 76.39, 76.39),
  ('REP-202609-0008', '1.1', 1539.49, 1539.49),
  ('REP-202609-0008', '1.2', 629.99, 629.99);
INSERT INTO RESPALDA (Num_reporte, Cod_obligacion, Monto_adeudado, Monto_pagado_rep) VALUES
  ('REP-202609-0008', '1.3', 1282.42, 1282.42),
  ('REP-202609-0008', '1.6', 555.72, 555.72),
  ('REP-202609-0009', '1.7', 1268.17, 1268.17),
  ('REP-202609-0010', '1.4', 175.26, 175.26),
  ('REP-202609-0010', '1.5', 101.17, 101.17),
  ('REP-202609-0010', '1.12', 85.49, 85.49),
  ('REP-202609-0011', '1.1', 0.00, 0.00),
  ('REP-202609-0011', '1.2', 640.67, 640.67),
  ('REP-202609-0011', '1.3', 1884.77, 1884.77),
  ('REP-202609-0011', '1.6', 816.74, 816.74),
  ('REP-202609-0012', '1.7', 1863.83, 1863.83),
  ('REP-202609-0013', '1.4', 257.59, 257.59),
  ('REP-202609-0013', '1.5', 148.69, 148.69),
  ('REP-202609-0013', '1.12', 125.65, 125.65),
  ('REP-202609-0014', '1.1', 4236.48, 4236.48),
  ('REP-202609-0014', '1.2', 1240.95, 1240.95),
  ('REP-202609-0014', '1.3', 1718.52, 1718.52),
  ('REP-202609-0014', '1.6', 744.69, 744.69),
  ('REP-202609-0015', '1.7', 1019.65, 1019.65),
  ('REP-202609-0016', '1.7', 679.77, 679.77),
  ('REP-202609-0017', '1.4', 234.86, 234.86),
  ('REP-202609-0017', '1.5', 135.57, 135.57),
  ('REP-202609-0017', '1.12', 114.57, 114.57),
  ('REP-202609-0018', '1.1', 1855.82, 1855.82),
  ('REP-202609-0018', '1.2', 988.22, 988.22),
  ('REP-202609-0018', '1.3', 1806.45, 1806.45),
  ('REP-202609-0018', '1.6', 782.79, 782.79),
  ('REP-202609-0019', '1.7', 1071.82, 1071.82),
  ('REP-202609-0020', '1.7', 714.55, 714.55),
  ('REP-202609-0021', '1.4', 246.88, 246.88),
  ('REP-202609-0021', '1.5', 142.51, 142.51),
  ('REP-202609-0021', '1.12', 120.43, 120.43),
  ('REP-202609-0021', '1.13', 80.29, 80.29),
  ('REP-202609-0022', '1.1', 8138.62, 8138.62),
  ('REP-202609-0022', '1.2', 2287.73, 2287.73),
  ('REP-202609-0022', '1.3', 2870.85, 2870.85),
  ('REP-202609-0022', '1.6', 1244.03, 1244.03),
  ('REP-202609-0023', '1.7', 2838.95, 2838.95),
  ('REP-202609-0024', '1.4', 392.35, 392.35),
  ('REP-202609-0024', '1.5', 226.48, 226.48),
  ('REP-202609-0024', '1.12', 191.39, 191.39),
  ('REP-202609-0025', '1.10', 262.50, 262.50),
  ('REP-202609-0026', '1.1', 3147.20, 3147.20),
  ('REP-202609-0026', '1.2', 1383.78, 1383.78),
  ('REP-202609-0026', '1.3', 1653.99, 1653.99),
  ('REP-202609-0026', '1.6', 716.73, 716.73),
  ('REP-202609-0027', '1.7', 981.37, 981.37),
  ('REP-202609-0028', '1.7', 654.24, 654.24),
  ('REP-202609-0029', '1.4', 226.04, 226.04),
  ('REP-202609-0029', '1.5', 130.48, 130.48),
  ('REP-202609-0029', '1.12', 110.27, 110.27),
  ('REP-202609-0030', '1.1', 5097.24, 5097.24),
  ('REP-202609-0030', '1.2', 1662.95, 1662.95),
  ('REP-202609-0030', '1.3', 2816.53, 2816.53),
  ('REP-202609-0030', '1.6', 1220.50, 1220.50),
  ('REP-202609-0031', '1.7', 2785.24, 2785.24),
  ('REP-202609-0032', '1.4', 384.93, 384.93),
  ('REP-202609-0032', '1.5', 222.19, 222.19),
  ('REP-202609-0032', '1.12', 187.77, 187.77),
  ('REP-202609-0033', '1.1', 1873.66, 1873.66),
  ('REP-202609-0033', '1.2', 954.02, 954.02),
  ('REP-202609-0033', '1.3', 2173.68, 2173.68),
  ('REP-202609-0033', '1.6', 941.93, 941.93),
  ('REP-202609-0034', '1.7', 2149.52, 2149.52),
  ('REP-202609-0035', '1.12', 144.91, 144.91),
  ('REP-202609-0036', '1.1', 1271.72, 1271.72),
  ('REP-202609-0036', '1.2', 517.66, 517.66),
  ('REP-202609-0036', '1.3', 1621.42, 1621.42),
  ('REP-202609-0036', '1.6', 702.62, 702.62),
  ('REP-202609-0037', '1.7', 1603.40, 1603.40),
  ('REP-202609-0038', '1.4', 221.59, 221.59),
  ('REP-202609-0038', '1.5', 127.91, 127.91),
  ('REP-202609-0038', '1.12', 108.09, 108.09),
  ('REP-202609-0039', '1.1', 6685.00, 6685.00),
  ('REP-202609-0039', '1.2', 2129.73, 2129.73),
  ('REP-202609-0039', '1.3', 3136.33, 3136.33),
  ('REP-202609-0039', '1.6', 1359.07, 1359.07),
  ('REP-202609-0040', '1.7', 1860.89, 1860.89),
  ('REP-202609-0041', '1.7', 1240.59, 1240.59),
  ('REP-202609-0042', '1.4', 428.63, 428.63),
  ('REP-202609-0042', '1.5', 247.42, 247.42),
  ('REP-202609-0042', '1.12', 209.09, 209.09),
  ('REP-202609-0043', '1.10', 237.50, 237.50),
  ('REP-202609-0044', '1.1', 4792.08, 4792.08),
  ('REP-202609-0044', '1.2', 1349.35, 1349.35),
  ('REP-202609-0044', '1.3', 2356.66, 2356.66),
  ('REP-202609-0044', '1.6', 1021.22, 1021.22),
  ('REP-202609-0045', '1.7', 1398.29, 1398.29),
  ('REP-202609-0046', '1.7', 932.19, 932.19),
  ('REP-202609-0047', '1.4', 322.08, 322.08),
  ('REP-202609-0047', '1.5', 185.91, 185.91),
  ('REP-202609-0047', '1.12', 157.11, 157.11),
  ('REP-202609-0048', '1.10', 145.00, 145.00),
  ('REP-202609-0049', '1.1', 6998.60, 6998.60),
  ('REP-202609-0049', '1.2', 2016.05, 2041.45),
  ('REP-202609-0049', '1.3', 3294.42, 3294.42),
  ('REP-202609-0049', '1.6', 1427.58, 1427.58),
  ('REP-202609-0050', '1.7', 1954.69, 1954.69),
  ('REP-202609-0051', '1.7', 1303.13, 1303.13),
  ('REP-202609-0052', '1.4', 450.24, 450.24);
INSERT INTO RESPALDA (Num_reporte, Cod_obligacion, Monto_adeudado, Monto_pagado_rep) VALUES
  ('REP-202609-0052', '1.5', 259.89, 259.89),
  ('REP-202609-0052', '1.12', 219.63, 219.63),
  ('REP-202609-0053', '1.11', 274.54, 274.54),
  ('REP-202609-0054', '1.1', 6472.77, 6472.77),
  ('REP-202609-0054', '1.2', 2502.99, 2502.99),
  ('REP-202609-0054', '1.3', 2951.90, 2951.90),
  ('REP-202609-0054', '1.6', 1279.16, 1288.96),
  ('REP-202609-0055', '1.7', 1751.46, 1751.46),
  ('REP-202609-0056', '1.7', 1167.64, 1167.64),
  ('REP-202609-0057', '1.4', 403.43, 403.43),
  ('REP-202609-0057', '1.5', 232.87, 232.87),
  ('REP-202609-0057', '1.12', 196.79, 196.79),
  ('REP-202609-0057', '1.13', 131.20, 131.20),
  ('REP-202609-0058', '1.1', 3461.82, 3461.82),
  ('REP-202609-0058', '1.2', 1093.96, 1093.96),
  ('REP-202609-0058', '1.3', 2420.64, 2420.64),
  ('REP-202609-0058', '1.6', 1048.94, 1048.94),
  ('REP-202609-0059', '1.7', 2393.74, 2393.74),
  ('REP-202609-0060', '1.4', 330.82, 330.82),
  ('REP-202609-0060', '1.5', 190.96, 190.96),
  ('REP-202609-0060', '1.12', 161.38, 161.38);

-- ----------------------------------------------------------------------------
-- VERIFICACIÓN: número de filas por tabla
-- ----------------------------------------------------------------------------
SELECT 'CONTRATISTA' AS Tabla, COUNT(*) AS Filas FROM CONTRATISTA
UNION ALL SELECT 'CENTRO_COSTO', COUNT(*) FROM CENTRO_COSTO
UNION ALL SELECT 'CARGO', COUNT(*) FROM CARGO
UNION ALL SELECT 'RECAUDADORA', COUNT(*) FROM RECAUDADORA
UNION ALL SELECT 'OBLIGACION_TRIBUTARIA', COUNT(*) FROM OBLIGACION_TRIBUTARIA
UNION ALL SELECT 'OBLIGACION_LEGAL', COUNT(*) FROM OBLIGACION_LEGAL
UNION ALL SELECT 'TELEFONO_CONTRATISTA', COUNT(*) FROM TELEFONO_CONTRATISTA
UNION ALL SELECT 'ANALISTA', COUNT(*) FROM ANALISTA
UNION ALL SELECT 'CONTRATO', COUNT(*) FROM CONTRATO
UNION ALL SELECT 'TRABAJADOR', COUNT(*) FROM TRABAJADOR
UNION ALL SELECT 'INSPECCION_OBLIGACIONES', COUNT(*) FROM INSPECCION_OBLIGACIONES
UNION ALL SELECT 'HES', COUNT(*) FROM HES
UNION ALL SELECT 'OBSERVACION', COUNT(*) FROM OBSERVACION
UNION ALL SELECT 'REPORTE_ENTIDAD', COUNT(*) FROM REPORTE_ENTIDAD
UNION ALL SELECT 'BOLETA_PAGO', COUNT(*) FROM BOLETA_PAGO
UNION ALL SELECT 'DECLARACION_JURADA', COUNT(*) FROM DECLARACION_JURADA
UNION ALL SELECT 'DECLARA', COUNT(*) FROM DECLARA
UNION ALL SELECT 'VERIFICA', COUNT(*) FROM VERIFICA
UNION ALL SELECT 'RESPALDA', COUNT(*) FROM RESPALDA;


-- ############################################################################
-- PARTE 3 DE 7: 04_historial_hes_spcc.sql
-- Base histórica y procedimiento de archivo
-- ############################################################################

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


-- ############################################################################
-- PARTE 4 DE 7: 05_aplicativo_hes_spcc.sql
-- Eliminación lógica, procedimientos de consulta y usuario app_hes
-- ############################################################################

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


-- ############################################################################
-- PARTE 5 DE 7: 06_crud_hes_spcc.sql
-- Procedimientos y triggers del registro, la edición y la eliminación lógica
-- ############################################################################

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


-- ############################################################################
-- PARTE 6 DE 7: 07_reportes_hes_spcc.sql
-- Reportes, trabajadores e inspecciones
-- ############################################################################

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


-- ############################################################################
-- PARTE 7 DE 7: 08_datos_adicionales_hes_spcc.sql
-- Más datos: periodo 10/2026
-- ############################################################################

-- ============================================================================
-- Base de datos: revisión y liberación de la HES (SPCC) - Software CARL-HES
-- Gestión de Datos e Información - UCSM. Quinta Entrega: script con más datos
-- Gestor: MySQL 8.0 con el motor InnoDB
-- Contenido: periodo 10/2026 completo (18 inspecciones y 18 HES emitidas en
--            noviembre de 2026), dos contratistas nuevas con sus contratos y
--            trabajadores, reportes de las entidades, boletas, verificaciones,
--            declaraciones, una declaración jurada y observaciones.
-- Orden: ejecutar después de 01, 02, 04, 05, 06 y 07, una sola vez. Los datos
--        pasan por los triggers de validación de los scripts 01, 05, 06 y 07.
-- ============================================================================

SET NAMES utf8mb4;
USE hes_spcc;

START TRANSACTION;

-- Contratistas nuevas y sus teléfonos
INSERT INTO CONTRATISTA (RUC, Razon_social) VALUES
  ('20539471826', 'Servicios Eléctricos Moquegua S.A.C.'),
  ('20541286703', 'Transportes y Logística Ilo S.R.L.');
INSERT INTO TELEFONO_CONTRATISTA (RUC, Telefono) VALUES
  ('20539471826', '053461927'),
  ('20539471826', '958274160'),
  ('20541286703', '053482915');

-- Contratos nuevos a cargo de la analista 104815
INSERT INTO CONTRATO (Num_contrato, Monto_total, RUC, Cod_centro_costo, Num_registro_analista) VALUES
  ('CT-004785', 1500000.00, '20539471826', 'ILFUN01', '104815'),
  ('CT-004792', 900000.00, '20541286703', 'ILPUE03', '104815');

-- Trabajadores de las contratistas nuevas
INSERT INTO TRABAJADOR (DNI, Apellidos, Nombres, RUC) VALUES
  ('45178813', 'Mamani Quispe', 'Rubén', '20539471826'),
  ('49449288', 'Condori Ticona', 'Yesenia', '20539471826'),
  ('43211939', 'Huanca Flores', 'Hernán', '20539471826'),
  ('48811701', 'Pari Choque', 'Gladys', '20539471826'),
  ('42190905', 'Calizaya Ramos', 'Wilson', '20539471826'),
  ('44190178', 'Laura Ccama', 'Rocío', '20539471826'),
  ('47786830', 'Nina Apaza', 'Edgar', '20541286703'),
  ('79330281', 'Coila Mendoza', 'Maribel', '20541286703'),
  ('76300557', 'Arapa Vilca', 'Jesús', '20541286703'),
  ('41919323', 'Cusi Pacheco', 'Lizbeth', '20541286703'),
  ('48593686', 'Chura Llanos', 'Ronald', '20541286703');

-- Inspecciones del periodo 10/2026
INSERT INTO INSPECCION_OBLIGACIONES (Num_inspeccion, Periodo, Firma_contratista) VALUES
  ('INS-2026-10-001', '202610', 'Firmado'),
  ('INS-2026-10-002', '202610', 'Firmado'),
  ('INS-2026-10-003', '202610', 'Firmado'),
  ('INS-2026-10-004', '202610', 'Firmado'),
  ('INS-2026-10-005', '202610', 'Firmado'),
  ('INS-2026-10-006', '202610', 'Firmado'),
  ('INS-2026-10-007', '202610', 'Firmado'),
  ('INS-2026-10-008', '202610', 'Firmado'),
  ('INS-2026-10-009', '202610', 'Firmado'),
  ('INS-2026-10-010', '202610', 'Firmado'),
  ('INS-2026-10-011', '202610', 'Firmado'),
  ('INS-2026-10-012', '202610', 'Firmado'),
  ('INS-2026-10-013', '202610', 'No firmado'),
  ('INS-2026-10-014', '202610', 'Firmado'),
  ('INS-2026-10-015', '202610', 'Firmado'),
  ('INS-2026-10-016', '202610', 'Firmado'),
  ('INS-2026-10-017', '202610', 'Firmado'),
  ('INS-2026-10-018', '202610', 'Firmado');

-- HES emitidas en noviembre de 2026 (la HES rechazada se registra pendiente y cambia de estado al final)
INSERT INTO HES (Num_HES, Fecha_emision, Estado, Monto_servicio, Num_inspeccion, Num_contrato) VALUES
  ('005256', '2026-11-02', 'Aprobada', 44325.02, 'INS-2026-10-001', 'CT-004733'),
  ('005257', '2026-11-03', 'Aprobada', 44323.31, 'INS-2026-10-002', 'CT-004402'),
  ('005258', '2026-11-03', 'Pendiente', 31834.93, 'INS-2026-10-003', 'CT-004671'),
  ('005259', '2026-11-04', 'Aprobada', 28657.98, 'INS-2026-10-004', 'CT-004702'),
  ('005260', '2026-11-04', 'Aprobada', 69185.45, 'INS-2026-10-005', 'CT-004750'),
  ('005261', '2026-11-05', 'Pendiente', 54921.39, 'INS-2026-10-006', 'CT-004608'),
  ('005262', '2026-11-05', 'Aprobada', 130553.87, 'INS-2026-10-007', 'CT-004613'),
  ('005263', '2026-11-06', 'Pendiente', 86443.26, 'INS-2026-10-008', 'CT-004532'),
  ('005264', '2026-11-06', 'Pendiente', 83570.33, 'INS-2026-10-009', 'CT-004589'),
  ('005265', '2026-11-09', 'Aprobada', 45122.56, 'INS-2026-10-010', 'CT-004640'),
  ('005266', '2026-11-09', 'Pendiente', 23090.42, 'INS-2026-10-011', 'CT-004688'),
  ('005267', '2026-11-10', 'Pendiente', 122565.45, 'INS-2026-10-012', 'CT-004517'),
  ('005268', '2026-11-10', 'Pendiente', 70426.48, 'INS-2026-10-013', 'CT-004719'),
  ('005269', '2026-11-11', 'Pendiente', 112677.54, 'INS-2026-10-014', 'CT-004655'),
  ('005270', '2026-11-11', 'Pendiente', 141553.68, 'INS-2026-10-015', 'CT-004455'),
  ('005271', '2026-11-12', 'Pendiente', 50391.30, 'INS-2026-10-016', 'CT-004768'),
  ('005272', '2026-11-12', 'Pendiente', 62480.35, 'INS-2026-10-017', 'CT-004785'),
  ('005273', '2026-11-13', 'Pendiente', 37215.60, 'INS-2026-10-018', 'CT-004792');

-- Obligaciones declaradas en cada formato de inspección
INSERT INTO DECLARA (Num_inspeccion, Cod_obligacion, Monto_declarado, Monto_pagado, Mora, Fecha_pago) VALUES
  ('INS-2026-10-001', '1.1', 1533.40, 1533.40, NULL, '2026-11-16'),
  ('INS-2026-10-001', '1.2', 841.67, 841.67, NULL, '2026-11-16'),
  ('INS-2026-10-001', '1.3', 1519.38, 1519.38, NULL, '2026-11-16'),
  ('INS-2026-10-001', '1.4', 207.65, 207.65, NULL, '2026-11-16'),
  ('INS-2026-10-001', '1.5', 119.87, 119.87, NULL, '2026-11-13'),
  ('INS-2026-10-001', '1.6', 658.40, 658.40, NULL, '2026-11-13'),
  ('INS-2026-10-001', '1.7', 1502.50, 1502.50, NULL, '2026-11-12'),
  ('INS-2026-10-001', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-10-001', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-10-001', '1.10', NULL, NULL, NULL, NULL),
  ('INS-2026-10-001', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-10-001', '1.12', 101.30, 101.30, NULL, '2026-11-16'),
  ('INS-2026-10-001', '1.13', 67.52, 67.52, NULL, '2026-11-13'),
  ('INS-2026-10-002', '1.1', 0.00, 0.00, NULL, '2026-11-12'),
  ('INS-2026-10-002', '1.2', 713.39, 713.39, NULL, '2026-11-16'),
  ('INS-2026-10-002', '1.3', 1123.92, 1123.92, NULL, '2026-11-13'),
  ('INS-2026-10-002', '1.4', 153.60, 153.60, NULL, '2026-11-13'),
  ('INS-2026-10-002', '1.5', 88.67, 88.67, NULL, '2026-11-13'),
  ('INS-2026-10-002', '1.6', 487.03, 487.03, NULL, '2026-11-12'),
  ('INS-2026-10-002', '1.7', 1111.43, 1111.43, NULL, '2026-11-12'),
  ('INS-2026-10-002', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-10-002', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-10-002', '1.10', NULL, NULL, NULL, NULL),
  ('INS-2026-10-002', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-10-002', '1.12', 74.93, 74.93, NULL, '2026-11-16'),
  ('INS-2026-10-002', '1.13', NULL, NULL, NULL, NULL),
  ('INS-2026-10-003', '1.1', 1511.11, 1511.11, NULL, '2026-11-13'),
  ('INS-2026-10-003', '1.2', 618.38, 618.38, NULL, '2026-11-16'),
  ('INS-2026-10-003', '1.3', 1258.78, 1276.63, 17.85, '2026-11-17'),
  ('INS-2026-10-003', '1.4', 172.03, 172.03, NULL, '2026-11-16'),
  ('INS-2026-10-003', '1.5', 99.31, 99.31, NULL, '2026-11-13'),
  ('INS-2026-10-003', '1.6', 545.48, 545.48, NULL, '2026-11-16'),
  ('INS-2026-10-003', '1.7', 1244.80, 1244.80, NULL, '2026-11-13'),
  ('INS-2026-10-003', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-10-003', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-10-003', '1.10', NULL, NULL, NULL, NULL),
  ('INS-2026-10-003', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-10-003', '1.12', 83.91, 83.91, NULL, '2026-11-12'),
  ('INS-2026-10-003', '1.13', NULL, NULL, NULL, NULL),
  ('INS-2026-10-004', '1.1', 0.00, 0.00, NULL, '2026-11-13'),
  ('INS-2026-10-004', '1.2', 647.26, 647.26, NULL, '2026-11-13'),
  ('INS-2026-10-004', '1.3', 1904.16, 1904.16, NULL, '2026-11-12'),
  ('INS-2026-10-004', '1.4', 260.24, 260.24, NULL, '2026-11-13'),
  ('INS-2026-10-004', '1.5', 150.22, 150.22, NULL, '2026-11-12'),
  ('INS-2026-10-004', '1.6', 825.14, 825.14, NULL, '2026-11-16'),
  ('INS-2026-10-004', '1.7', 1883.00, 1883.00, NULL, '2026-11-13'),
  ('INS-2026-10-004', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-10-004', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-10-004', '1.10', NULL, NULL, NULL, NULL),
  ('INS-2026-10-004', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-10-004', '1.12', 126.94, 126.94, NULL, '2026-11-13'),
  ('INS-2026-10-004', '1.13', NULL, NULL, NULL, NULL),
  ('INS-2026-10-005', '1.1', 4356.96, 4356.96, NULL, '2026-11-13'),
  ('INS-2026-10-005', '1.2', 1276.24, 1276.24, NULL, '2026-11-13'),
  ('INS-2026-10-005', '1.3', 1767.39, 1767.39, NULL, '2026-11-16'),
  ('INS-2026-10-005', '1.4', 241.54, 241.54, NULL, '2026-11-12'),
  ('INS-2026-10-005', '1.5', 139.43, 139.43, NULL, '2026-11-13'),
  ('INS-2026-10-005', '1.6', 765.87, 765.87, NULL, '2026-11-13'),
  ('INS-2026-10-005', '1.7', 1747.75, 1747.75, NULL, '2026-11-13'),
  ('INS-2026-10-005', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-10-005', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-10-005', '1.10', NULL, NULL, NULL, NULL),
  ('INS-2026-10-005', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-10-005', '1.12', 117.83, 117.83, NULL, '2026-11-13'),
  ('INS-2026-10-005', '1.13', NULL, NULL, NULL, NULL),
  ('INS-2026-10-006', '1.1', 1839.79, 1839.79, NULL, '2026-11-12'),
  ('INS-2026-10-006', '1.2', 979.68, 979.68, NULL, '2026-11-13'),
  ('INS-2026-10-006', '1.3', 1790.85, 1790.85, NULL, '2026-11-12'),
  ('INS-2026-10-006', '1.4', 244.75, 244.75, NULL, '2026-11-13'),
  ('INS-2026-10-006', '1.5', 141.28, 141.28, NULL, '2026-11-13'),
  ('INS-2026-10-006', '1.6', 776.03, 776.03, NULL, '2026-11-12'),
  ('INS-2026-10-006', '1.7', 1770.94, 1770.94, NULL, '2026-11-12'),
  ('INS-2026-10-006', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-10-006', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-10-006', '1.10', NULL, NULL, NULL, NULL),
  ('INS-2026-10-006', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-10-006', '1.12', 119.39, 119.39, NULL, '2026-11-12'),
  ('INS-2026-10-006', '1.13', 79.60, 79.60, NULL, '2026-11-12'),
  ('INS-2026-10-007', '1.1', 8270.93, 8270.93, NULL, '2026-11-13'),
  ('INS-2026-10-007', '1.2', 2324.92, 2324.92, NULL, '2026-11-13'),
  ('INS-2026-10-007', '1.3', 2917.52, 2917.52, NULL, '2026-11-13'),
  ('INS-2026-10-007', '1.4', 398.73, 398.73, NULL, '2026-11-12'),
  ('INS-2026-10-007', '1.5', 230.16, 230.16, NULL, '2026-11-16'),
  ('INS-2026-10-007', '1.6', 1264.25, 1264.25, NULL, '2026-11-16'),
  ('INS-2026-10-007', '1.7', 2885.10, 2885.10, NULL, '2026-11-16'),
  ('INS-2026-10-007', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-10-007', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-10-007', '1.10', 266.77, 266.77, NULL, '2026-11-13'),
  ('INS-2026-10-007', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-10-007', '1.12', 194.50, 194.50, NULL, '2026-11-13'),
  ('INS-2026-10-007', '1.13', NULL, NULL, NULL, NULL),
  ('INS-2026-10-008', '1.1', 3100.16, 3100.16, NULL, '2026-11-16'),
  ('INS-2026-10-008', '1.2', 1363.10, 1363.10, NULL, '2026-11-13'),
  ('INS-2026-10-008', '1.3', 1629.27, 1629.27, NULL, '2026-11-13'),
  ('INS-2026-10-008', '1.4', 222.66, 222.66, NULL, '2026-11-13'),
  ('INS-2026-10-008', '1.5', 128.53, 128.53, NULL, '2026-11-12'),
  ('INS-2026-10-008', '1.6', 706.02, 706.02, NULL, '2026-11-16'),
  ('INS-2026-10-008', '1.7', 1611.16, 1611.16, NULL, '2026-11-12'),
  ('INS-2026-10-008', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-10-008', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-10-008', '1.10', NULL, NULL, NULL, NULL),
  ('INS-2026-10-008', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-10-008', '1.12', 108.62, 108.62, NULL, '2026-11-16'),
  ('INS-2026-10-008', '1.13', NULL, NULL, NULL, NULL),
  ('INS-2026-10-009', '1.1', 4958.83, 4958.83, NULL, '2026-11-13'),
  ('INS-2026-10-009', '1.2', 1617.79, 1617.79, NULL, '2026-11-13'),
  ('INS-2026-10-009', '1.3', 2740.05, 2740.05, NULL, '2026-11-12'),
  ('INS-2026-10-009', '1.4', 374.48, 374.48, NULL, '2026-11-13'),
  ('INS-2026-10-009', '1.5', 216.16, 216.16, NULL, '2026-11-13'),
  ('INS-2026-10-009', '1.6', 1187.36, 1187.36, NULL, '2026-11-13'),
  ('INS-2026-10-009', '1.7', 2709.61, 2709.61, NULL, '2026-11-12'),
  ('INS-2026-10-009', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-10-009', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-10-009', '1.10', NULL, NULL, NULL, NULL),
  ('INS-2026-10-009', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-10-009', '1.12', 182.67, 182.67, NULL, '2026-11-13'),
  ('INS-2026-10-009', '1.13', NULL, NULL, NULL, NULL),
  ('INS-2026-10-010', '1.1', 1943.20, 1943.20, NULL, '2026-11-16'),
  ('INS-2026-10-010', '1.2', 989.43, 989.43, NULL, '2026-11-16'),
  ('INS-2026-10-010', '1.3', 2254.35, 2254.35, NULL, '2026-11-12'),
  ('INS-2026-10-010', '1.4', 308.10, 308.10, NULL, '2026-11-16'),
  ('INS-2026-10-010', '1.5', 177.84, 177.84, NULL, '2026-11-13'),
  ('INS-2026-10-010', '1.6', 976.89, 976.89, NULL, '2026-11-13'),
  ('INS-2026-10-010', '1.7', 2229.30, 2229.30, NULL, '2026-11-13'),
  ('INS-2026-10-010', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-10-010', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-10-010', '1.10', NULL, NULL, NULL, NULL),
  ('INS-2026-10-010', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-10-010', '1.12', 150.29, 150.29, NULL, '2026-11-12'),
  ('INS-2026-10-010', '1.13', NULL, NULL, NULL, NULL),
  ('INS-2026-10-011', '1.1', 1288.75, 1288.75, NULL, '2026-11-13'),
  ('INS-2026-10-011', '1.2', 524.59, 524.59, NULL, '2026-11-13'),
  ('INS-2026-10-011', '1.3', 1643.14, 1643.14, NULL, '2026-11-12'),
  ('INS-2026-10-011', '1.4', 224.56, 224.56, NULL, '2026-11-13'),
  ('INS-2026-10-011', '1.5', 129.62, 129.62, NULL, '2026-11-13'),
  ('INS-2026-10-011', '1.6', 712.03, 712.03, NULL, '2026-11-12'),
  ('INS-2026-10-011', '1.7', 1624.88, 1647.28, 22.40, '2026-11-17'),
  ('INS-2026-10-011', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-10-011', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-10-011', '1.10', NULL, NULL, NULL, NULL),
  ('INS-2026-10-011', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-10-011', '1.12', 109.54, 109.54, NULL, '2026-11-16'),
  ('INS-2026-10-011', '1.13', NULL, NULL, NULL, NULL),
  ('INS-2026-10-012', '1.1', 6772.81, 6772.81, NULL, '2026-11-12'),
  ('INS-2026-10-012', '1.2', 2157.70, 2157.70, NULL, '2026-11-13'),
  ('INS-2026-10-012', '1.3', 3177.52, 3177.52, NULL, '2026-11-13'),
  ('INS-2026-10-012', '1.4', 434.26, 434.26, NULL, '2026-11-13'),
  ('INS-2026-10-012', '1.5', 250.67, 250.67, NULL, '2026-11-16'),
  ('INS-2026-10-012', '1.6', 1376.92, 1376.92, NULL, '2026-11-12'),
  ('INS-2026-10-012', '1.7', 3142.22, 3142.22, NULL, '2026-11-13'),
  ('INS-2026-10-012', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-10-012', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-10-012', '1.10', 240.62, 240.62, NULL, '2026-11-13'),
  ('INS-2026-10-012', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-10-012', '1.12', 211.84, 211.84, NULL, '2026-11-16'),
  ('INS-2026-10-012', '1.13', NULL, NULL, NULL, NULL),
  ('INS-2026-10-013', '1.1', 4684.91, 4684.91, NULL, '2026-11-13'),
  ('INS-2026-10-013', '1.2', 1319.17, 1319.17, NULL, '2026-11-13'),
  ('INS-2026-10-013', '1.3', 2303.95, 2303.95, NULL, '2026-11-12'),
  ('INS-2026-10-013', '1.4', 314.88, 314.88, NULL, '2026-11-12'),
  ('INS-2026-10-013', '1.5', 181.75, 181.75, NULL, '2026-11-13'),
  ('INS-2026-10-013', '1.6', 998.38, 998.38, NULL, '2026-11-16'),
  ('INS-2026-10-013', '1.7', 2278.36, 2278.36, NULL, '2026-11-12'),
  ('INS-2026-10-013', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-10-013', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-10-013', '1.10', 141.76, 141.76, NULL, '2026-11-16'),
  ('INS-2026-10-013', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-10-013', '1.12', 153.60, 153.60, NULL, '2026-11-12'),
  ('INS-2026-10-013', '1.13', NULL, NULL, NULL, NULL),
  ('INS-2026-10-014', '1.1', 6859.11, 6859.11, NULL, '2026-11-16'),
  ('INS-2026-10-014', '1.2', 1975.87, 1975.87, NULL, '2026-11-13'),
  ('INS-2026-10-014', '1.3', 3228.76, 3228.76, NULL, '2026-11-13'),
  ('INS-2026-10-014', '1.4', 441.27, 441.27, NULL, '2026-11-16'),
  ('INS-2026-10-014', '1.5', 254.71, 254.71, NULL, '2026-11-12'),
  ('INS-2026-10-014', '1.6', 1399.13, 1399.13, NULL, '2026-11-13'),
  ('INS-2026-10-014', '1.7', 3192.89, 3192.89, NULL, '2026-11-13'),
  ('INS-2026-10-014', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-10-014', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-10-014', '1.10', NULL, NULL, NULL, NULL),
  ('INS-2026-10-014', '1.11', 269.07, 269.07, NULL, '2026-11-12'),
  ('INS-2026-10-014', '1.12', 215.25, 215.25, NULL, '2026-11-16'),
  ('INS-2026-10-014', '1.13', NULL, NULL, NULL, NULL),
  ('INS-2026-10-015', '1.1', 6685.58, 6685.58, NULL, '2026-11-16'),
  ('INS-2026-10-015', '1.2', 2585.28, 2585.28, NULL, '2026-11-12'),
  ('INS-2026-10-015', '1.3', 3048.95, 3048.95, NULL, '2026-11-16'),
  ('INS-2026-10-015', '1.4', 416.69, 416.69, NULL, '2026-11-13'),
  ('INS-2026-10-015', '1.5', 240.53, 240.53, NULL, '2026-11-12'),
  ('INS-2026-10-015', '1.6', 1321.22, 1321.22, NULL, '2026-11-16'),
  ('INS-2026-10-015', '1.7', 3015.07, 3015.07, NULL, '2026-11-13'),
  ('INS-2026-10-015', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-10-015', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-10-015', '1.10', NULL, NULL, NULL, NULL),
  ('INS-2026-10-015', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-10-015', '1.12', 203.26, 203.26, NULL, '2026-11-13'),
  ('INS-2026-10-015', '1.13', 135.51, 135.51, NULL, '2026-11-16'),
  ('INS-2026-10-016', '1.1', 3507.33, 3507.33, NULL, '2026-11-12'),
  ('INS-2026-10-016', '1.2', 1108.34, 1108.34, NULL, '2026-11-13'),
  ('INS-2026-10-016', '1.3', 2452.46, 2537.46, NULL, '2026-11-13'),
  ('INS-2026-10-016', '1.4', 335.17, 335.17, NULL, '2026-11-13'),
  ('INS-2026-10-016', '1.5', 193.47, 193.47, NULL, '2026-11-13'),
  ('INS-2026-10-016', '1.6', 1062.73, 1062.73, NULL, '2026-11-13'),
  ('INS-2026-10-016', '1.7', 2425.21, 2425.21, NULL, '2026-11-13'),
  ('INS-2026-10-016', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-10-016', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-10-016', '1.10', NULL, NULL, NULL, NULL),
  ('INS-2026-10-016', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-10-016', '1.12', 163.50, 163.50, NULL, '2026-11-16'),
  ('INS-2026-10-016', '1.13', NULL, NULL, NULL, NULL),
  ('INS-2026-10-017', '1.1', 1918.68, 1918.68, NULL, '2026-11-13'),
  ('INS-2026-10-017', '1.2', 1021.69, 1021.69, NULL, '2026-11-16'),
  ('INS-2026-10-017', '1.3', 1867.64, 1867.64, NULL, '2026-11-13'),
  ('INS-2026-10-017', '1.4', 255.24, 255.24, NULL, '2026-11-16'),
  ('INS-2026-10-017', '1.5', 147.34, 147.34, NULL, '2026-11-13'),
  ('INS-2026-10-017', '1.6', 809.31, 809.31, NULL, '2026-11-12'),
  ('INS-2026-10-017', '1.7', 1846.88, 1846.88, NULL, '2026-11-16'),
  ('INS-2026-10-017', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-10-017', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-10-017', '1.10', NULL, NULL, NULL, NULL),
  ('INS-2026-10-017', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-10-017', '1.12', 124.51, 124.51, NULL, '2026-11-16'),
  ('INS-2026-10-017', '1.13', 83.01, 83.01, NULL, '2026-11-13'),
  ('INS-2026-10-018', '1.1', 1275.76, 1275.76, NULL, '2026-11-13'),
  ('INS-2026-10-018', '1.2', 519.30, 519.30, NULL, '2026-11-13'),
  ('INS-2026-10-018', '1.3', 1626.57, 1626.57, NULL, '2026-11-16'),
  ('INS-2026-10-018', '1.4', 222.29, 222.29, NULL, '2026-11-13'),
  ('INS-2026-10-018', '1.5', 128.32, 128.32, NULL, '2026-11-13'),
  ('INS-2026-10-018', '1.6', 704.85, 704.85, NULL, '2026-11-16'),
  ('INS-2026-10-018', '1.7', 1608.49, 1608.49, NULL, '2026-11-13'),
  ('INS-2026-10-018', '1.8', NULL, NULL, NULL, NULL),
  ('INS-2026-10-018', '1.9', NULL, NULL, NULL, NULL),
  ('INS-2026-10-018', '1.10', NULL, NULL, NULL, NULL),
  ('INS-2026-10-018', '1.11', NULL, NULL, NULL, NULL),
  ('INS-2026-10-018', '1.12', 108.43, 108.43, NULL, '2026-11-13'),
  ('INS-2026-10-018', '1.13', NULL, NULL, NULL, NULL);

-- Reportes de las entidades recaudadoras
INSERT INTO REPORTE_ENTIDAD (Num_reporte, Cod_entidad, Num_inspeccion) VALUES
  ('REP-202610-0001', 1, 'INS-2026-10-001'),
  ('REP-202610-0002', 4, 'INS-2026-10-001'),
  ('REP-202610-0003', 5, 'INS-2026-10-001'),
  ('REP-202610-0004', 9, 'INS-2026-10-001'),
  ('REP-202610-0005', 1, 'INS-2026-10-002'),
  ('REP-202610-0006', 5, 'INS-2026-10-002'),
  ('REP-202610-0007', 10, 'INS-2026-10-002'),
  ('REP-202610-0008', 1, 'INS-2026-10-003'),
  ('REP-202610-0009', 5, 'INS-2026-10-003'),
  ('REP-202610-0010', 8, 'INS-2026-10-003'),
  ('REP-202610-0011', 1, 'INS-2026-10-004'),
  ('REP-202610-0012', 4, 'INS-2026-10-004'),
  ('REP-202610-0013', 8, 'INS-2026-10-004'),
  ('REP-202610-0014', 1, 'INS-2026-10-005'),
  ('REP-202610-0015', 5, 'INS-2026-10-005'),
  ('REP-202610-0016', 6, 'INS-2026-10-005'),
  ('REP-202610-0017', 10, 'INS-2026-10-005'),
  ('REP-202610-0018', 1, 'INS-2026-10-006'),
  ('REP-202610-0019', 4, 'INS-2026-10-006'),
  ('REP-202610-0020', 5, 'INS-2026-10-006'),
  ('REP-202610-0021', 9, 'INS-2026-10-006'),
  ('REP-202610-0022', 1, 'INS-2026-10-007'),
  ('REP-202610-0023', 7, 'INS-2026-10-007'),
  ('REP-202610-0024', 10, 'INS-2026-10-007'),
  ('REP-202610-0025', 11, 'INS-2026-10-007'),
  ('REP-202610-0026', 1, 'INS-2026-10-008'),
  ('REP-202610-0027', 5, 'INS-2026-10-008'),
  ('REP-202610-0028', 6, 'INS-2026-10-008'),
  ('REP-202610-0029', 10, 'INS-2026-10-008'),
  ('REP-202610-0030', 1, 'INS-2026-10-009'),
  ('REP-202610-0031', 6, 'INS-2026-10-009'),
  ('REP-202610-0032', 8, 'INS-2026-10-009'),
  ('REP-202610-0033', 1, 'INS-2026-10-010'),
  ('REP-202610-0034', 4, 'INS-2026-10-010'),
  ('REP-202610-0035', 9, 'INS-2026-10-010'),
  ('REP-202610-0036', 1, 'INS-2026-10-011'),
  ('REP-202610-0037', 5, 'INS-2026-10-011'),
  ('REP-202610-0038', 9, 'INS-2026-10-011'),
  ('REP-202610-0039', 1, 'INS-2026-10-012'),
  ('REP-202610-0040', 4, 'INS-2026-10-012'),
  ('REP-202610-0041', 5, 'INS-2026-10-012'),
  ('REP-202610-0042', 8, 'INS-2026-10-012'),
  ('REP-202610-0043', 11, 'INS-2026-10-012'),
  ('REP-202610-0044', 1, 'INS-2026-10-013'),
  ('REP-202610-0045', 4, 'INS-2026-10-013'),
  ('REP-202610-0046', 5, 'INS-2026-10-013'),
  ('REP-202610-0047', 8, 'INS-2026-10-013'),
  ('REP-202610-0048', 11, 'INS-2026-10-013'),
  ('REP-202610-0049', 1, 'INS-2026-10-014'),
  ('REP-202610-0050', 4, 'INS-2026-10-014'),
  ('REP-202610-0051', 7, 'INS-2026-10-014'),
  ('REP-202610-0052', 8, 'INS-2026-10-014'),
  ('REP-202610-0053', 12, 'INS-2026-10-014'),
  ('REP-202610-0054', 1, 'INS-2026-10-015'),
  ('REP-202610-0055', 7, 'INS-2026-10-015'),
  ('REP-202610-0056', 4, 'INS-2026-10-015'),
  ('REP-202610-0057', 9, 'INS-2026-10-015'),
  ('REP-202610-0058', 1, 'INS-2026-10-016'),
  ('REP-202610-0059', 6, 'INS-2026-10-016'),
  ('REP-202610-0060', 8, 'INS-2026-10-016'),
  ('REP-202610-0061', 1, 'INS-2026-10-017'),
  ('REP-202610-0062', 4, 'INS-2026-10-017'),
  ('REP-202610-0063', 5, 'INS-2026-10-017'),
  ('REP-202610-0064', 9, 'INS-2026-10-017'),
  ('REP-202610-0065', 1, 'INS-2026-10-018'),
  ('REP-202610-0066', 5, 'INS-2026-10-018'),
  ('REP-202610-0067', 9, 'INS-2026-10-018');

-- Montos que respalda cada reporte
INSERT INTO RESPALDA (Num_reporte, Cod_obligacion, Monto_adeudado, Monto_pagado_rep) VALUES
  ('REP-202610-0001', '1.1', 1533.40, 1533.40),
  ('REP-202610-0001', '1.2', 841.67, 841.67),
  ('REP-202610-0001', '1.3', 1519.38, 1519.38),
  ('REP-202610-0001', '1.6', 658.40, 658.40),
  ('REP-202610-0002', '1.7', 901.50, 901.50),
  ('REP-202610-0003', '1.7', 601.00, 601.00),
  ('REP-202610-0004', '1.12', 101.30, 101.30),
  ('REP-202610-0004', '1.13', 67.52, 67.52),
  ('REP-202610-0004', '1.4', 207.65, 207.65),
  ('REP-202610-0004', '1.5', 119.87, 119.87),
  ('REP-202610-0005', '1.1', 0.00, 0.00),
  ('REP-202610-0005', '1.2', 713.39, 713.39),
  ('REP-202610-0005', '1.3', 1123.92, 1123.92),
  ('REP-202610-0005', '1.6', 487.03, 487.03),
  ('REP-202610-0006', '1.7', 1111.43, 1111.43),
  ('REP-202610-0007', '1.12', 74.93, 74.93),
  ('REP-202610-0007', '1.4', 153.60, 153.60),
  ('REP-202610-0007', '1.5', 88.67, 88.67),
  ('REP-202610-0008', '1.1', 1511.11, 1511.11),
  ('REP-202610-0008', '1.2', 618.38, 618.38),
  ('REP-202610-0008', '1.3', 1258.78, 1276.63),
  ('REP-202610-0008', '1.6', 545.48, 545.48),
  ('REP-202610-0009', '1.7', 1244.80, 1244.80),
  ('REP-202610-0010', '1.12', 83.91, 83.91),
  ('REP-202610-0010', '1.4', 172.03, 172.03),
  ('REP-202610-0010', '1.5', 99.31, 99.31),
  ('REP-202610-0011', '1.1', 0.00, 0.00),
  ('REP-202610-0011', '1.2', 647.26, 647.26),
  ('REP-202610-0011', '1.3', 1904.16, 1904.16),
  ('REP-202610-0011', '1.6', 825.14, 825.14),
  ('REP-202610-0012', '1.7', 1883.00, 1883.00),
  ('REP-202610-0013', '1.12', 126.94, 126.94),
  ('REP-202610-0013', '1.4', 260.24, 260.24),
  ('REP-202610-0013', '1.5', 150.22, 150.22),
  ('REP-202610-0014', '1.1', 4356.96, 4356.96),
  ('REP-202610-0014', '1.2', 1276.24, 1276.24),
  ('REP-202610-0014', '1.3', 1767.39, 1767.39),
  ('REP-202610-0014', '1.6', 765.87, 765.87),
  ('REP-202610-0015', '1.7', 1048.65, 1048.65),
  ('REP-202610-0016', '1.7', 699.10, 699.10),
  ('REP-202610-0017', '1.12', 117.83, 117.83),
  ('REP-202610-0017', '1.4', 241.54, 241.54),
  ('REP-202610-0017', '1.5', 139.43, 139.43),
  ('REP-202610-0018', '1.1', 1839.79, 1839.79),
  ('REP-202610-0018', '1.2', 979.68, 979.68),
  ('REP-202610-0018', '1.3', 1790.85, 1790.85),
  ('REP-202610-0018', '1.6', 776.03, 776.03),
  ('REP-202610-0019', '1.7', 1062.56, 1062.56),
  ('REP-202610-0020', '1.7', 708.38, 708.38),
  ('REP-202610-0021', '1.12', 119.39, 119.39),
  ('REP-202610-0021', '1.13', 79.60, 79.60),
  ('REP-202610-0021', '1.4', 244.75, 244.75),
  ('REP-202610-0021', '1.5', 141.28, 141.28),
  ('REP-202610-0022', '1.1', 8270.93, 8270.93),
  ('REP-202610-0022', '1.2', 2324.92, 2324.92),
  ('REP-202610-0022', '1.3', 2917.52, 2917.52),
  ('REP-202610-0022', '1.6', 1264.25, 1264.25),
  ('REP-202610-0023', '1.7', 2885.10, 2885.10),
  ('REP-202610-0024', '1.12', 194.50, 194.50),
  ('REP-202610-0024', '1.4', 398.73, 398.73),
  ('REP-202610-0024', '1.5', 230.16, 230.16),
  ('REP-202610-0025', '1.10', 266.77, 266.77),
  ('REP-202610-0026', '1.1', 3100.16, 3100.16),
  ('REP-202610-0026', '1.2', 1363.10, 1363.10),
  ('REP-202610-0026', '1.3', 1629.27, 1629.27),
  ('REP-202610-0026', '1.6', 706.02, 706.02),
  ('REP-202610-0027', '1.7', 966.70, 966.70),
  ('REP-202610-0028', '1.7', 644.46, 644.46),
  ('REP-202610-0029', '1.12', 108.62, 108.62),
  ('REP-202610-0029', '1.4', 222.66, 222.66),
  ('REP-202610-0029', '1.5', 128.53, 128.53),
  ('REP-202610-0030', '1.1', 4958.83, 4958.83),
  ('REP-202610-0030', '1.2', 1617.79, 1617.79),
  ('REP-202610-0030', '1.3', 2740.05, 2740.05),
  ('REP-202610-0030', '1.6', 1187.36, 1187.36),
  ('REP-202610-0031', '1.7', 2709.61, 2709.61),
  ('REP-202610-0032', '1.12', 182.67, 182.67),
  ('REP-202610-0032', '1.4', 374.48, 374.48),
  ('REP-202610-0032', '1.5', 216.16, 216.16),
  ('REP-202610-0033', '1.1', 1943.20, 1943.20),
  ('REP-202610-0033', '1.2', 989.43, 989.43),
  ('REP-202610-0033', '1.3', 2254.35, 2254.35),
  ('REP-202610-0033', '1.6', 976.89, 976.89),
  ('REP-202610-0034', '1.7', 2229.30, 2229.30),
  ('REP-202610-0035', '1.12', 150.29, 150.29),
  ('REP-202610-0036', '1.1', 1288.75, 1288.75),
  ('REP-202610-0036', '1.2', 524.59, 524.59),
  ('REP-202610-0036', '1.3', 1643.14, 1643.14),
  ('REP-202610-0036', '1.6', 712.03, 712.03),
  ('REP-202610-0037', '1.7', 1624.88, 1647.28),
  ('REP-202610-0038', '1.12', 109.54, 109.54),
  ('REP-202610-0038', '1.4', 224.56, 224.56),
  ('REP-202610-0038', '1.5', 129.62, 129.62),
  ('REP-202610-0039', '1.1', 6772.81, 6772.81),
  ('REP-202610-0039', '1.2', 2157.70, 2157.70),
  ('REP-202610-0039', '1.3', 3177.52, 3177.52),
  ('REP-202610-0039', '1.6', 1376.92, 1376.92),
  ('REP-202610-0040', '1.7', 1885.33, 1885.33),
  ('REP-202610-0041', '1.7', 1256.89, 1256.89),
  ('REP-202610-0042', '1.12', 211.84, 211.84),
  ('REP-202610-0042', '1.4', 434.26, 434.26),
  ('REP-202610-0042', '1.5', 250.67, 250.67),
  ('REP-202610-0043', '1.10', 240.62, 240.62),
  ('REP-202610-0044', '1.1', 4684.91, 4684.91),
  ('REP-202610-0044', '1.2', 1319.17, 1319.17),
  ('REP-202610-0044', '1.3', 2303.95, 2303.95),
  ('REP-202610-0044', '1.6', 998.38, 998.38),
  ('REP-202610-0045', '1.7', 1367.02, 1367.02),
  ('REP-202610-0046', '1.7', 911.34, 911.34),
  ('REP-202610-0047', '1.12', 153.60, 153.60),
  ('REP-202610-0047', '1.4', 314.88, 314.88),
  ('REP-202610-0047', '1.5', 181.75, 181.75),
  ('REP-202610-0048', '1.10', 141.76, 141.76),
  ('REP-202610-0049', '1.1', 6859.11, 6859.11),
  ('REP-202610-0049', '1.2', 1975.87, 1975.87),
  ('REP-202610-0049', '1.3', 3228.76, 3228.76),
  ('REP-202610-0049', '1.6', 1399.13, 1399.13),
  ('REP-202610-0050', '1.7', 1915.73, 1915.73),
  ('REP-202610-0051', '1.7', 1277.16, 1277.16),
  ('REP-202610-0052', '1.12', 215.25, 215.25),
  ('REP-202610-0052', '1.4', 441.27, 441.27),
  ('REP-202610-0052', '1.5', 254.71, 254.71),
  ('REP-202610-0053', '1.11', 269.07, 269.07),
  ('REP-202610-0054', '1.1', 6685.58, 6685.58),
  ('REP-202610-0054', '1.2', 2585.28, 2585.28),
  ('REP-202610-0054', '1.3', 3048.95, 3048.95),
  ('REP-202610-0054', '1.6', 1321.22, 1321.22),
  ('REP-202610-0055', '1.7', 1809.04, 1809.04),
  ('REP-202610-0056', '1.7', 1206.03, 1206.03),
  ('REP-202610-0057', '1.12', 203.26, 203.26),
  ('REP-202610-0057', '1.13', 135.51, 135.51),
  ('REP-202610-0057', '1.4', 416.69, 416.69),
  ('REP-202610-0057', '1.5', 240.53, 240.53),
  ('REP-202610-0058', '1.1', 3507.33, 3507.33),
  ('REP-202610-0058', '1.2', 1108.34, 1108.34),
  ('REP-202610-0058', '1.3', 2452.46, 2452.46),
  ('REP-202610-0058', '1.6', 1062.73, 1062.73),
  ('REP-202610-0059', '1.7', 2425.21, 2425.21),
  ('REP-202610-0060', '1.12', 163.50, 163.50),
  ('REP-202610-0060', '1.4', 335.17, 335.17),
  ('REP-202610-0060', '1.5', 193.47, 193.47),
  ('REP-202610-0061', '1.1', 1918.68, 1918.68),
  ('REP-202610-0061', '1.2', 1021.69, 1021.69),
  ('REP-202610-0061', '1.3', 1867.64, 1867.64),
  ('REP-202610-0061', '1.6', 809.31, 809.31),
  ('REP-202610-0062', '1.7', 1108.13, 1108.13),
  ('REP-202610-0063', '1.7', 738.75, 738.75),
  ('REP-202610-0064', '1.12', 124.51, 124.51),
  ('REP-202610-0064', '1.13', 83.01, 83.01),
  ('REP-202610-0064', '1.4', 255.24, 255.24),
  ('REP-202610-0064', '1.5', 147.34, 147.34),
  ('REP-202610-0065', '1.1', 1275.76, 1275.76),
  ('REP-202610-0065', '1.2', 519.30, 519.30),
  ('REP-202610-0065', '1.3', 1626.57, 1626.57),
  ('REP-202610-0065', '1.6', 704.85, 704.85),
  ('REP-202610-0066', '1.7', 1608.49, 1608.49),
  ('REP-202610-0067', '1.12', 108.43, 108.43),
  ('REP-202610-0067', '1.4', 222.29, 222.29),
  ('REP-202610-0067', '1.5', 128.32, 128.32);

-- Boletas de pago de los trabajadores
INSERT INTO BOLETA_PAGO (Num_boleta, Firma_trabajador, DNI, Num_inspeccion) VALUES
  ('BOL-202610-0001', 'Firmada', '76065004', 'INS-2026-10-001'),
  ('BOL-202610-0002', 'Firmada', '47728258', 'INS-2026-10-001'),
  ('BOL-202610-0003', 'Firmada', '76953642', 'INS-2026-10-001'),
  ('BOL-202610-0004', 'Firmada', '42276165', 'INS-2026-10-001'),
  ('BOL-202610-0005', 'Firmada', '76616396', 'INS-2026-10-001'),
  ('BOL-202610-0006', 'Firmada', '72116961', 'INS-2026-10-001'),
  ('BOL-202610-0007', 'Firmada', '42173460', 'INS-2026-10-002'),
  ('BOL-202610-0008', 'Firmada', '71523270', 'INS-2026-10-002'),
  ('BOL-202610-0009', 'Firmada', '75296053', 'INS-2026-10-002'),
  ('BOL-202610-0010', 'Firmada', '46830184', 'INS-2026-10-002'),
  ('BOL-202610-0011', 'Firmada', '43368451', 'INS-2026-10-002'),
  ('BOL-202610-0012', 'Firmada', '42436230', 'INS-2026-10-003'),
  ('BOL-202610-0013', 'Firmada', '46083695', 'INS-2026-10-003'),
  ('BOL-202610-0014', 'Firmada', '72275217', 'INS-2026-10-003'),
  ('BOL-202610-0015', 'Firmada', '43510587', 'INS-2026-10-003'),
  ('BOL-202610-0016', 'Firmada', '71271679', 'INS-2026-10-003'),
  ('BOL-202610-0017', 'Firmada', '74338638', 'INS-2026-10-003'),
  ('BOL-202610-0018', 'Firmada', '41406079', 'INS-2026-10-004'),
  ('BOL-202610-0019', 'Firmada', '72387158', 'INS-2026-10-004'),
  ('BOL-202610-0020', 'Firmada', '46695880', 'INS-2026-10-004'),
  ('BOL-202610-0021', 'Firmada', '74743120', 'INS-2026-10-004'),
  ('BOL-202610-0022', 'Firmada', '71383122', 'INS-2026-10-004'),
  ('BOL-202610-0023', 'Firmada', '45950756', 'INS-2026-10-005'),
  ('BOL-202610-0024', 'Firmada', '42219803', 'INS-2026-10-005'),
  ('BOL-202610-0025', 'Firmada', '72502438', 'INS-2026-10-005'),
  ('BOL-202610-0026', 'Firmada', '44423950', 'INS-2026-10-005'),
  ('BOL-202610-0027', 'Firmada', '45768741', 'INS-2026-10-005'),
  ('BOL-202610-0028', 'Firmada', '72493759', 'INS-2026-10-005'),
  ('BOL-202610-0029', 'Firmada', '74368538', 'INS-2026-10-005'),
  ('BOL-202610-0030', 'Firmada', '76581112', 'INS-2026-10-006'),
  ('BOL-202610-0031', 'Firmada', '47165365', 'INS-2026-10-006'),
  ('BOL-202610-0032', 'Firmada', '40131777', 'INS-2026-10-006'),
  ('BOL-202610-0033', 'Firmada', '71873068', 'INS-2026-10-006'),
  ('BOL-202610-0034', 'Firmada', '70079389', 'INS-2026-10-006'),
  ('BOL-202610-0035', 'Firmada', '45457987', 'INS-2026-10-006'),
  ('BOL-202610-0036', 'Firmada', '45731722', 'INS-2026-10-006'),
  ('BOL-202610-0037', 'Firmada', '42163254', 'INS-2026-10-007'),
  ('BOL-202610-0038', 'Firmada', '40177862', 'INS-2026-10-007'),
  ('BOL-202610-0039', 'Firmada', '43708948', 'INS-2026-10-007'),
  ('BOL-202610-0040', 'Firmada', '46625414', 'INS-2026-10-007'),
  ('BOL-202610-0041', 'Firmada', '74813733', 'INS-2026-10-007'),
  ('BOL-202610-0042', 'Firmada', '45414231', 'INS-2026-10-007'),
  ('BOL-202610-0043', 'Firmada', '42240425', 'INS-2026-10-007'),
  ('BOL-202610-0044', 'Firmada', '71518007', 'INS-2026-10-007'),
  ('BOL-202610-0045', 'Firmada', '73206828', 'INS-2026-10-008'),
  ('BOL-202610-0046', 'Firmada', '48126126', 'INS-2026-10-008'),
  ('BOL-202610-0047', 'Firmada', '73596879', 'INS-2026-10-008'),
  ('BOL-202610-0048', 'Firmada', '47979758', 'INS-2026-10-008'),
  ('BOL-202610-0049', 'Firmada', '47336743', 'INS-2026-10-008'),
  ('BOL-202610-0050', 'Firmada', '40865140', 'INS-2026-10-008'),
  ('BOL-202610-0051', 'Firmada', '43364705', 'INS-2026-10-008'),
  ('BOL-202610-0052', 'Firmada', '73257171', 'INS-2026-10-009'),
  ('BOL-202610-0053', 'Firmada', '46500139', 'INS-2026-10-009'),
  ('BOL-202610-0054', 'Firmada', '73930805', 'INS-2026-10-009'),
  ('BOL-202610-0055', 'Firmada', '42812093', 'INS-2026-10-009'),
  ('BOL-202610-0056', 'Firmada', '73112728', 'INS-2026-10-009'),
  ('BOL-202610-0057', 'Firmada', '75751651', 'INS-2026-10-009'),
  ('BOL-202610-0058', 'Firmada', '47388246', 'INS-2026-10-009'),
  ('BOL-202610-0059', 'Firmada', '71815739', 'INS-2026-10-010'),
  ('BOL-202610-0060', 'Firmada', '43324473', 'INS-2026-10-010'),
  ('BOL-202610-0061', 'Firmada', '73928916', 'INS-2026-10-010'),
  ('BOL-202610-0062', 'Firmada', '46352975', 'INS-2026-10-010'),
  ('BOL-202610-0063', 'Firmada', '46230283', 'INS-2026-10-010'),
  ('BOL-202610-0064', 'Firmada', '40752228', 'INS-2026-10-011'),
  ('BOL-202610-0065', 'Firmada', '74002617', 'INS-2026-10-011'),
  ('BOL-202610-0066', 'Firmada', '40908215', 'INS-2026-10-011'),
  ('BOL-202610-0067', 'Firmada', '75587395', 'INS-2026-10-011'),
  ('BOL-202610-0068', 'Firmada', '71905242', 'INS-2026-10-011'),
  ('BOL-202610-0069', 'Firmada', '48299424', 'INS-2026-10-012'),
  ('BOL-202610-0070', 'Firmada', '75955639', 'INS-2026-10-012'),
  ('BOL-202610-0071', 'Firmada', '70180423', 'INS-2026-10-012'),
  ('BOL-202610-0072', 'Firmada', '70907576', 'INS-2026-10-012'),
  ('BOL-202610-0073', 'Firmada', '72315353', 'INS-2026-10-012'),
  ('BOL-202610-0074', 'Firmada', '71342606', 'INS-2026-10-012'),
  ('BOL-202610-0075', 'Firmada', '72015528', 'INS-2026-10-012'),
  ('BOL-202610-0076', 'Firmada', '40065537', 'INS-2026-10-012'),
  ('BOL-202610-0077', 'Firmada', '76652718', 'INS-2026-10-013'),
  ('BOL-202610-0078', 'Firmada', '76006912', 'INS-2026-10-013'),
  ('BOL-202610-0079', 'Firmada', '71540558', 'INS-2026-10-013'),
  ('BOL-202610-0080', 'Firmada', '43751737', 'INS-2026-10-013'),
  ('BOL-202610-0081', 'Firmada', '44376048', 'INS-2026-10-013'),
  ('BOL-202610-0082', 'Firmada', '43761680', 'INS-2026-10-013'),
  ('BOL-202610-0083', 'Firmada', '44441759', 'INS-2026-10-014'),
  ('BOL-202610-0084', 'Firmada', '74915035', 'INS-2026-10-014'),
  ('BOL-202610-0085', 'Firmada', '46476573', 'INS-2026-10-014'),
  ('BOL-202610-0086', 'Firmada', '71728206', 'INS-2026-10-014'),
  ('BOL-202610-0087', 'Firmada', '71675500', 'INS-2026-10-014'),
  ('BOL-202610-0088', 'Firmada', '71012734', 'INS-2026-10-014'),
  ('BOL-202610-0089', 'Firmada', '42982232', 'INS-2026-10-014'),
  ('BOL-202610-0090', 'Firmada', '72879685', 'INS-2026-10-014'),
  ('BOL-202610-0091', 'Firmada', '40916276', 'INS-2026-10-015'),
  ('BOL-202610-0092', 'No firmada', '73963527', 'INS-2026-10-015'),
  ('BOL-202610-0093', 'Firmada', '43892914', 'INS-2026-10-015'),
  ('BOL-202610-0094', 'Firmada', '75444200', 'INS-2026-10-015'),
  ('BOL-202610-0095', 'No firmada', '40644902', 'INS-2026-10-015'),
  ('BOL-202610-0096', 'Firmada', '45520843', 'INS-2026-10-015'),
  ('BOL-202610-0097', 'Firmada', '76965074', 'INS-2026-10-015'),
  ('BOL-202610-0098', 'Firmada', '41579947', 'INS-2026-10-015'),
  ('BOL-202610-0099', 'Firmada', '73899177', 'INS-2026-10-016'),
  ('BOL-202610-0100', 'Firmada', '46724988', 'INS-2026-10-016'),
  ('BOL-202610-0101', 'Firmada', '45023399', 'INS-2026-10-016'),
  ('BOL-202610-0102', 'Firmada', '74553619', 'INS-2026-10-016'),
  ('BOL-202610-0103', 'Firmada', '73363762', 'INS-2026-10-016'),
  ('BOL-202610-0104', 'Firmada', '71080618', 'INS-2026-10-016'),
  ('BOL-202610-0105', 'Firmada', '47786830', 'INS-2026-10-018'),
  ('BOL-202610-0106', 'Firmada', '79330281', 'INS-2026-10-018'),
  ('BOL-202610-0107', 'Firmada', '76300557', 'INS-2026-10-018'),
  ('BOL-202610-0108', 'Firmada', '41919323', 'INS-2026-10-018'),
  ('BOL-202610-0109', 'Firmada', '48593686', 'INS-2026-10-018');

-- Verificación de las obligaciones legales
INSERT INTO VERIFICA (Num_inspeccion, Cod_obligacion_legal, Cumplimiento) VALUES
  ('INS-2026-10-001', '2.1', 'OK'),
  ('INS-2026-10-001', '2.2', 'OK'),
  ('INS-2026-10-001', '2.5', 'OK'),
  ('INS-2026-10-001', '2.6', 'OK'),
  ('INS-2026-10-002', '2.1', 'OK'),
  ('INS-2026-10-002', '2.2', 'OK'),
  ('INS-2026-10-002', '2.5', 'OK'),
  ('INS-2026-10-002', '2.6', 'OK'),
  ('INS-2026-10-003', '2.1', 'OK'),
  ('INS-2026-10-003', '2.2', 'OK'),
  ('INS-2026-10-003', '2.5', 'OK'),
  ('INS-2026-10-003', '2.6', 'OK'),
  ('INS-2026-10-004', '2.1', 'OK'),
  ('INS-2026-10-004', '2.2', 'OK'),
  ('INS-2026-10-004', '2.5', 'OK'),
  ('INS-2026-10-004', '2.6', 'No aplica'),
  ('INS-2026-10-005', '2.1', 'OK'),
  ('INS-2026-10-005', '2.2', 'OK'),
  ('INS-2026-10-005', '2.5', 'OK'),
  ('INS-2026-10-005', '2.6', 'OK'),
  ('INS-2026-10-006', '2.1', 'OK'),
  ('INS-2026-10-006', '2.2', 'OK'),
  ('INS-2026-10-006', '2.5', 'OK'),
  ('INS-2026-10-006', '2.6', 'OK'),
  ('INS-2026-10-007', '2.1', 'OK'),
  ('INS-2026-10-007', '2.2', 'OK'),
  ('INS-2026-10-007', '2.5', 'OK'),
  ('INS-2026-10-007', '2.6', 'OK'),
  ('INS-2026-10-008', '2.1', 'OK'),
  ('INS-2026-10-008', '2.2', 'OK'),
  ('INS-2026-10-008', '2.5', 'OK'),
  ('INS-2026-10-008', '2.6', 'OK'),
  ('INS-2026-10-009', '2.1', 'OK'),
  ('INS-2026-10-009', '2.2', 'OK'),
  ('INS-2026-10-009', '2.5', 'OK'),
  ('INS-2026-10-009', '2.6', 'OK'),
  ('INS-2026-10-010', '2.1', 'OK'),
  ('INS-2026-10-010', '2.2', 'OK'),
  ('INS-2026-10-010', '2.5', 'OK'),
  ('INS-2026-10-010', '2.6', 'OK'),
  ('INS-2026-10-011', '2.1', 'OK'),
  ('INS-2026-10-011', '2.2', 'OK'),
  ('INS-2026-10-011', '2.5', 'OK'),
  ('INS-2026-10-011', '2.6', 'No aplica'),
  ('INS-2026-10-012', '2.1', 'OK'),
  ('INS-2026-10-012', '2.2', 'OK'),
  ('INS-2026-10-012', '2.5', 'OK'),
  ('INS-2026-10-012', '2.6', 'OK'),
  ('INS-2026-10-013', '2.1', 'OK'),
  ('INS-2026-10-013', '2.2', 'OK'),
  ('INS-2026-10-013', '2.5', 'OK'),
  ('INS-2026-10-013', '2.6', 'OK'),
  ('INS-2026-10-014', '2.1', 'OK'),
  ('INS-2026-10-014', '2.2', 'OK'),
  ('INS-2026-10-014', '2.5', 'OK'),
  ('INS-2026-10-014', '2.6', 'OK'),
  ('INS-2026-10-015', '2.1', 'OK'),
  ('INS-2026-10-015', '2.2', 'OK'),
  ('INS-2026-10-015', '2.5', 'OK'),
  ('INS-2026-10-015', '2.6', 'OK'),
  ('INS-2026-10-016', '2.1', 'OK'),
  ('INS-2026-10-016', '2.2', 'OK'),
  ('INS-2026-10-016', '2.5', 'OK'),
  ('INS-2026-10-016', '2.6', 'OK'),
  ('INS-2026-10-017', '2.1', 'OK'),
  ('INS-2026-10-017', '2.2', 'OK'),
  ('INS-2026-10-017', '2.5', 'OK'),
  ('INS-2026-10-017', '2.6', 'OK'),
  ('INS-2026-10-018', '2.1', 'OK'),
  ('INS-2026-10-018', '2.2', 'OK'),
  ('INS-2026-10-018', '2.5', 'OK'),
  ('INS-2026-10-018', '2.6', 'No aplica');

-- Declaración jurada de compromiso de pago
INSERT INTO DECLARACION_JURADA (Num_declaracion, Fecha_compromiso_pago, Num_inspeccion) VALUES
  ('DJ-202610-001', '2026-12-04', 'INS-2026-10-003');

-- Observaciones de las analistas (solo en HES pendientes)
INSERT INTO OBSERVACION (Num_HES, Num_observacion, Fecha_observacion, Comentario) VALUES
  ('005258', '1', '2026-11-13', 'Se registra mora en EsSalud; la contratista presentó la declaración jurada con compromiso de pago al 04/12/2026. Adjuntar la constancia de pago cuando se regularice.'),
  ('005263', '1', '2026-11-10', 'Los montos del formato corresponden al periodo 09/2026 y no al periodo 10/2026; se rechaza la HES para que el usuario emita una nueva.'),
  ('005266', '1', '2026-11-17', 'Se registra mora en AFP; levantar la mora y presentar la declaración jurada con la fecha de compromiso de pago.'),
  ('005268', '1', '2026-11-12', 'El formato de inspección no está firmado por el representante de la contratista.'),
  ('005270', '1', '2026-11-16', 'Dos boletas de pago del periodo 10/2026 no están firmadas por los trabajadores; la obligación 2.2 figura como cumplida en el formato.'),
  ('005271', '1', '2026-11-13', 'El monto pagado de EsSalud en el formato no coincide con el reporte PLAME de SUNAT.'),
  ('005271', '2', '2026-11-17', 'La contratista no corrigió el monto pagado de EsSalud en el formato; volver a presentar el formato corregido.'),
  ('005272', '1', '2026-11-16', 'Faltan las boletas de pago del personal del periodo 10/2026.');

-- La HES 005263 se rechaza después de registrar su observación
UPDATE HES SET Estado = 'Rechazada' WHERE Num_HES = '005263';

COMMIT;

-- ----------------------------------------------------------------------------
-- VERIFICACIÓN
-- ----------------------------------------------------------------------------
SELECT i.Periodo, COUNT(*) AS HES, SUM(h.Estado = 'Pendiente') AS Pendientes, SUM(h.Monto_servicio) AS Monto
FROM HES h JOIN INSPECCION_OBLIGACIONES i ON i.Num_inspeccion = h.Num_inspeccion
WHERE i.Periodo = '202610' GROUP BY i.Periodo;

SELECT (SELECT COUNT(*) FROM CONTRATISTA) AS Contratistas, (SELECT COUNT(*) FROM CONTRATO) AS Contratos,
       (SELECT COUNT(*) FROM TRABAJADOR) AS Trabajadores, (SELECT COUNT(*) FROM HES) AS HES,
       (SELECT COUNT(*) FROM DECLARA) AS Declara, (SELECT COUNT(*) FROM BOLETA_PAGO) AS Boletas,
       (SELECT COUNT(*) FROM REPORTE_ENTIDAD) AS Reportes, (SELECT COUNT(*) FROM RESPALDA) AS Respalda,
       (SELECT COUNT(*) FROM OBSERVACION) AS Observaciones;
