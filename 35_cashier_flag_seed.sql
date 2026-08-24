-- =====================================================================
-- Seed 35: flag 'cashier' RETROATIVA (W3.2 — Abertura/Fechamento de
-- Caixa, parecer setes-conceito 2026-08-22).
--
-- Institutions NOVAS ganham 'cashier' pelo insertDefaultFlags; este script
-- cobre as CRIADAS ANTES. Idempotente (NOT EXISTS).
-- Executar após script 34.
-- =====================================================================

USE `setes_central`;

INSERT IGNORE INTO `tb_feature_flag`
  (`id`, `tb_institution_id`, `module_key`, `enabled`, `created_at`, `updated_at`, `deleted`)
SELECT (SELECT COALESCE(MAX(f2.id), 0) FROM `tb_feature_flag` f2) + i.rn,
       i.id, 'cashier', TRUE, NOW(), NOW(), 'N'
FROM (
  SELECT t.id, ROW_NUMBER() OVER (ORDER BY t.id) AS rn
  FROM `tb_institution` t
  WHERE t.deleted = 'N'
    AND NOT EXISTS (SELECT 1 FROM `tb_feature_flag` f
                    WHERE f.tb_institution_id = t.id
                      AND f.module_key = 'cashier')
) i;
