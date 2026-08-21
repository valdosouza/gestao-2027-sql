-- =====================================================================
-- Seed 32: flag 'billing' RETROATIVA + interface do faturamento com a
-- config invoice_serie (W2 Onda 3, 2026-08-20 — rodada R4 do
-- prompt_fase_faturamento_financeiro.md).
--
-- A interface 'billing' existe para ANCORAR a config no Framework de
-- Configurações (série da nota — resolução usuário→institution→default);
-- kind 'R' = recurso (não aparece no menu; sem tela própria ainda).
--
-- Institutions NOVAS ganham 'billing' pelo insertDefaultFlags; este script
-- cobre as CRIADAS ANTES. Idempotente (INSERT IGNORE / NOT EXISTS).
-- Executar após scripts 01..31.
-- =====================================================================

USE `setes_central`;

-- Flag retroativa (mesmo shape do seed 29/31)
INSERT IGNORE INTO `tb_feature_flag`
  (`id`, `tb_institution_id`, `module_key`, `enabled`, `created_at`, `updated_at`, `deleted`)
SELECT (SELECT COALESCE(MAX(f2.id), 0) FROM `tb_feature_flag` f2) + i.rn,
       i.id, 'billing', TRUE, NOW(), NOW(), 'N'
FROM (
  SELECT t.id, ROW_NUMBER() OVER (ORDER BY t.id) AS rn
  FROM `tb_institution` t
  WHERE t.deleted = 'N'
    AND NOT EXISTS (SELECT 1 FROM `tb_feature_flag` f
                    WHERE f.tb_institution_id = t.id
                      AND f.module_key = 'billing')
) i;

-- Interface 'billing' (kind 'R' — recurso, fora do menu) p/ ancorar config
INSERT INTO `tb_interface`
  (`id`, `i18n_key`, `description`, `kind`, `created_at`, `updated_at`, `deleted`)
SELECT (SELECT COALESCE(MAX(i2.id), 0) + 1 FROM `tb_interface` i2),
       'billing', 'Faturamento de ordens', 'R', NOW(), NOW(), 'N'
WHERE NOT EXISTS (SELECT 1 FROM `tb_interface` WHERE i18n_key = 'billing');

-- Config invoice_serie (default '1', escopo Institution) no catálogo
INSERT INTO `tb_interface_has_config`
  (`tb_interface_id`, `name`, `description`, `kind`, `options`,
   `default_content`, `scope`, `created_at`, `updated_at`, `deleted`)
SELECT i.id, 'invoice_serie', 'Série da nota fiscal emitida pelo faturamento',
       'String', NULL, '1', 'I', NOW(), NOW(), 'N'
FROM `tb_interface` i
WHERE i.i18n_key = 'billing'
  AND NOT EXISTS (SELECT 1 FROM `tb_interface_has_config` c
                  WHERE c.tb_interface_id = i.id AND c.name = 'invoice_serie');
