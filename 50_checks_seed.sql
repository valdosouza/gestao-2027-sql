-- =====================================================================
-- Seed 50: interface 'checks' (Cheques — tela de processo: depositar,
-- descontar, retornar, usar em pagamento, devolver, estornar) —
-- prompt_cheque_rastreabilidade.md D1–D10 + D7a–c (2026-09-04).
-- Grupo "Financial". id DINÂMICO (MAX+1 — lição do seed 40). Idempotente.
-- Acompanha a migration 040 (setes-api). Executar após o script 49.
-- =====================================================================

USE `setes_central`;

-- Cheques (módulo checks — /api/checks ↔ /home/checks)
INSERT INTO `tb_interface`
  (`id`, `group_default`, `i18n_key`, `description`, `kind`, `position`, `created_at`, `updated_at`, `deleted`)
SELECT (SELECT COALESCE(MAX(i2.`id`), 0) + 1 FROM `tb_interface` i2),
       'Financial', 'checks', 'Checks', 'T', NULL, NOW(), NOW(), 'N'
 WHERE NOT EXISTS (SELECT 1 FROM `tb_interface`
                    WHERE `i18n_key` = 'checks' AND `deleted` = 'N');

-- Contrato da Setes (institution 1 — dev/dogfooding)
INSERT IGNORE INTO `setes_setes`.`tb_institution_has_interface`
  (`tb_institution_id`, `tb_interface_id`, `active`, `created_at`, `updated_at`, `deleted`)
SELECT 1, i.`id`, 'S', NOW(), NOW(), 'N'
  FROM `tb_interface` i
 WHERE i.`deleted` = 'N' AND i.`i18n_key` = 'checks';

-- Paginação (regra: lista nova nasce paginada — seed 22)
INSERT IGNORE INTO `tb_interface_has_config`
  (`tb_interface_id`, `name`, `description`, `kind`, `options`, `default_content`, `scope`, `created_at`, `updated_at`, `deleted`)
SELECT i.`id`, 'page_size',
       'Número de itens exibidos por página na lista de pesquisa.',
       'Options', '10=10;25=25;50=50;100=100', '25', 'U', NOW(), NOW(), 'N'
  FROM `tb_interface` i
 WHERE i.`deleted` = 'N' AND i.`i18n_key` = 'checks';

-- Gate técnico do módulo /api/checks para institutions EXISTENTES
INSERT IGNORE INTO `tb_feature_flag`
  (`id`, `tb_institution_id`, `module_key`, `enabled`, `created_at`, `updated_at`, `deleted`)
SELECT (SELECT COALESCE(MAX(f2.id), 0) FROM `tb_feature_flag` f2) + i.rn,
       i.id, 'checks', TRUE, NOW(), NOW(), 'N'
FROM (
  SELECT t.id, ROW_NUMBER() OVER (ORDER BY t.id) AS rn
  FROM `tb_institution` t
  WHERE t.deleted = 'N'
    AND NOT EXISTS (SELECT 1 FROM `tb_feature_flag` f
                    WHERE f.tb_institution_id = t.id
                      AND f.module_key = 'checks')
) i;
