-- =====================================================================
-- Seed 39: flag 'order-returns' RETROATIVA (Devolução de Mercadoria,
-- 2026-08-24 — parecer setes-conceito da mesma data).
--
-- Institutions NOVAS ganham a flag pelo insertDefaultFlags; este script
-- cobre as CRIADAS ANTES. Idempotente (NOT EXISTS).
-- Executar após script 38.
-- =====================================================================

USE `setes_central`;

INSERT IGNORE INTO `tb_feature_flag`
  (`id`, `tb_institution_id`, `module_key`, `enabled`, `created_at`, `updated_at`, `deleted`)
SELECT (SELECT COALESCE(MAX(f2.id), 0) FROM `tb_feature_flag` f2) + i.rn,
       i.id, 'order-returns', TRUE, NOW(), NOW(), 'N'
FROM (
  SELECT t.id, ROW_NUMBER() OVER (ORDER BY t.id) AS rn
  FROM `tb_institution` t
  WHERE t.deleted = 'N'
    AND NOT EXISTS (SELECT 1 FROM `tb_feature_flag` f
                    WHERE f.tb_institution_id = t.id
                      AND f.module_key = 'order-returns')
) i;
