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
