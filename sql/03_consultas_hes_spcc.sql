-- ============================================================================
-- Base de datos: revisión y liberación de la HES (SPCC)
-- Cuarta Entrega: consultas de la Analista de Contratos
-- Ejecutar completo, después de los scripts de creación y de inserción de datos.
-- Las variables definen la analista, el periodo, la HES y la inspección consultados.
-- ============================================================================

USE hes_spcc;

SET @analista   = '104390';
SET @periodo    = '202607';
SET @hes        = '005214';
SET @inspeccion = 'INS-2026-07-007';

-- 1. HES pendientes de una analista, de la más antigua a la más reciente
SELECT h.Num_HES, h.Fecha_emision,
       DATEDIFF(CURDATE(), h.Fecha_emision) AS Dias_en_espera,
       c.Num_contrato, ct.Razon_social, h.Monto_servicio
FROM HES h
JOIN CONTRATO c     ON c.Num_contrato = h.Num_contrato
JOIN CONTRATISTA ct ON ct.RUC = c.RUC
WHERE h.Estado = 'Pendiente'
  AND c.Num_registro_analista = @analista
ORDER BY h.Fecha_emision;

-- 2. Carga de trabajo de cada analista: contratos a cargo y HES pendientes
SELECT a.Num_registro,
       CONCAT(a.Apellidos, ', ', a.Nombres) AS Analista,
       COUNT(DISTINCT c.Num_contrato) AS Contratos_a_cargo,
       COALESCE(SUM(h.Estado = 'Pendiente'), 0) AS HES_pendientes
FROM ANALISTA a
LEFT JOIN CONTRATO c ON c.Num_registro_analista = a.Num_registro
LEFT JOIN HES h      ON h.Num_contrato = c.Num_contrato
GROUP BY a.Num_registro, a.Apellidos, a.Nombres
ORDER BY HES_pendientes DESC, Analista;

-- 3. Historial de observaciones de una HES
SELECT h.Num_HES, ct.Razon_social, h.Estado,
       o.Num_observacion, o.Fecha_observacion, o.Comentario
FROM OBSERVACION o
JOIN HES h          ON h.Num_HES = o.Num_HES
JOIN CONTRATO c     ON c.Num_contrato = h.Num_contrato
JOIN CONTRATISTA ct ON ct.RUC = c.RUC
WHERE o.Num_HES = @hes
ORDER BY o.Num_observacion;

-- 4. HES observadas más de una vez
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

-- 5. Contratistas con HES observadas pendientes de subsanar y sus teléfonos
SELECT ct.RUC, ct.Razon_social,
       COUNT(DISTINCT h.Num_HES) AS HES_por_subsanar,
       (SELECT GROUP_CONCAT(t.Telefono ORDER BY t.Telefono SEPARATOR ', ')
        FROM TELEFONO_CONTRATISTA t
        WHERE t.RUC = ct.RUC) AS Telefonos
FROM CONTRATISTA ct
JOIN CONTRATO c ON c.RUC = ct.RUC
JOIN HES h      ON h.Num_contrato = c.Num_contrato
WHERE h.Estado = 'Pendiente'
  AND EXISTS (SELECT 1 FROM OBSERVACION o WHERE o.Num_HES = h.Num_HES)
GROUP BY ct.RUC, ct.Razon_social
ORDER BY HES_por_subsanar DESC, ct.Razon_social;

-- 6. Inspecciones del periodo con documentación incompleta
SELECT i.Num_inspeccion, h.Num_HES, ct.Razon_social, i.Firma_contratista,
       (SELECT COUNT(*) FROM REPORTE_ENTIDAD re
        WHERE re.Num_inspeccion = i.Num_inspeccion) AS Reportes_entidad,
       (SELECT COUNT(*) FROM BOLETA_PAGO b
        WHERE b.Num_inspeccion = i.Num_inspeccion) AS Boletas
FROM INSPECCION_OBLIGACIONES i
JOIN HES h          ON h.Num_inspeccion = i.Num_inspeccion
JOIN CONTRATO c     ON c.Num_contrato = h.Num_contrato
JOIN CONTRATISTA ct ON ct.RUC = c.RUC
WHERE i.Periodo = @periodo
  AND (i.Firma_contratista = 'No firmado'
       OR NOT EXISTS (SELECT 1 FROM REPORTE_ENTIDAD re
                      WHERE re.Num_inspeccion = i.Num_inspeccion)
       OR NOT EXISTS (SELECT 1 FROM BOLETA_PAGO b
                      WHERE b.Num_inspeccion = i.Num_inspeccion))
ORDER BY ct.Razon_social;

-- 7. Conformidad de las obligaciones de una inspección (formato frente a los reportes de las entidades).
--    La CTS (1.8) y la gratificación (1.9) se verifican con las boletas (consulta 10).
SELECT d.Cod_obligacion, ot.Nom_obligacion,
       d.Monto_declarado, r.Monto_adeudado,
       d.Monto_pagado, r.Monto_pagado_rep,
       CASE WHEN d.Monto_declarado = r.Monto_adeudado
             AND d.Monto_pagado = r.Monto_pagado_rep THEN 'Conforme'
            ELSE 'Observado' END AS Conformidad
FROM DECLARA d
JOIN OBLIGACION_TRIBUTARIA ot ON ot.Cod_obligacion = d.Cod_obligacion
LEFT JOIN (SELECT re.Num_inspeccion, rs.Cod_obligacion,
                  SUM(rs.Monto_adeudado)   AS Monto_adeudado,
                  SUM(rs.Monto_pagado_rep) AS Monto_pagado_rep
           FROM REPORTE_ENTIDAD re
           JOIN RESPALDA rs ON rs.Num_reporte = re.Num_reporte
           GROUP BY re.Num_inspeccion, rs.Cod_obligacion) r
       ON r.Num_inspeccion = d.Num_inspeccion
      AND r.Cod_obligacion = d.Cod_obligacion
WHERE d.Num_inspeccion = @inspeccion
  AND d.Monto_declarado IS NOT NULL
  AND d.Cod_obligacion NOT IN ('1.8', '1.9')
ORDER BY CAST(SUBSTRING_INDEX(d.Cod_obligacion, '.', -1) AS UNSIGNED);

-- 8. Mora del periodo por contratista y obligación
SELECT ct.Razon_social, h.Num_HES, h.Estado, ot.Nom_obligacion AS Obligacion,
       d.Monto_declarado AS Declarado, d.Monto_pagado AS Pagado, d.Mora, d.Fecha_pago
FROM DECLARA d
JOIN OBLIGACION_TRIBUTARIA ot  ON ot.Cod_obligacion = d.Cod_obligacion
JOIN INSPECCION_OBLIGACIONES i ON i.Num_inspeccion = d.Num_inspeccion
JOIN HES h                     ON h.Num_inspeccion = i.Num_inspeccion
JOIN CONTRATO c                ON c.Num_contrato = h.Num_contrato
JOIN CONTRATISTA ct            ON ct.RUC = c.RUC
WHERE i.Periodo = @periodo
  AND d.Mora > 0
ORDER BY ct.Razon_social, d.Mora DESC;

-- 9. HES pendientes con mora y la situación de su declaración jurada
SELECT h.Num_HES, i.Periodo, ct.Razon_social, m.Mora_total,
       dj.Num_declaracion, dj.Fecha_compromiso_pago,
       CASE WHEN dj.Num_declaracion IS NULL THEN 'Falta declaración jurada'
            WHEN dj.Fecha_compromiso_pago < CURDATE() THEN 'Compromiso vencido'
            ELSE 'Con declaración jurada vigente' END AS Situacion
FROM (SELECT Num_inspeccion, SUM(Mora) AS Mora_total
      FROM DECLARA
      WHERE Mora > 0
      GROUP BY Num_inspeccion) m
JOIN INSPECCION_OBLIGACIONES i  ON i.Num_inspeccion = m.Num_inspeccion
JOIN HES h                      ON h.Num_inspeccion = m.Num_inspeccion
JOIN CONTRATO c                 ON c.Num_contrato = h.Num_contrato
JOIN CONTRATISTA ct             ON ct.RUC = c.RUC
LEFT JOIN DECLARACION_JURADA dj ON dj.Num_inspeccion = m.Num_inspeccion
WHERE h.Estado = 'Pendiente'
ORDER BY i.Periodo, ct.Razon_social;

-- 10. Pago de CTS y gratificación en el periodo, por HES de una analista
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
WHERE i.Periodo = @periodo
  AND c.Num_registro_analista = @analista
  AND d.Cod_obligacion IN ('1.8', '1.9')
GROUP BY h.Num_HES, ct.Razon_social
ORDER BY h.Num_HES;

-- 11. Boletas sin firma en inspecciones que marcan "Boletas de pago firmadas" (2.2) como OK
SELECT i.Num_inspeccion, i.Periodo, ct.Razon_social,
       COUNT(*) AS Boletas_sin_firma,
       GROUP_CONCAT(CONCAT(t.Apellidos, ', ', t.Nombres)
                    ORDER BY t.Apellidos SEPARATOR '; ') AS Trabajadores
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

-- 12. HES aprobadas del periodo para el memo de facturación de una analista
SELECT h.Num_HES, h.Fecha_emision, c.Num_contrato, ct.Razon_social,
       cc.Nombre_centro_costo, h.Monto_servicio
FROM HES h
JOIN INSPECCION_OBLIGACIONES i ON i.Num_inspeccion = h.Num_inspeccion
JOIN CONTRATO c                ON c.Num_contrato = h.Num_contrato
JOIN CONTRATISTA ct            ON ct.RUC = c.RUC
JOIN CENTRO_COSTO cc           ON cc.Cod_centro_costo = c.Cod_centro_costo
WHERE h.Estado = 'Aprobada'
  AND i.Periodo = @periodo
  AND c.Num_registro_analista = @analista
ORDER BY ct.Razon_social, h.Num_HES;

-- 13. Monto aprobado por centro de costo en el periodo
SELECT cc.Cod_centro_costo, cc.Nombre_centro_costo,
       COUNT(*) AS HES_aprobadas,
       SUM(h.Monto_servicio) AS Monto_total
FROM HES h
JOIN INSPECCION_OBLIGACIONES i ON i.Num_inspeccion = h.Num_inspeccion
JOIN CONTRATO c                ON c.Num_contrato = h.Num_contrato
JOIN CENTRO_COSTO cc           ON cc.Cod_centro_costo = c.Cod_centro_costo
WHERE h.Estado = 'Aprobada'
  AND i.Periodo = @periodo
GROUP BY cc.Cod_centro_costo, cc.Nombre_centro_costo
ORDER BY Monto_total DESC;
