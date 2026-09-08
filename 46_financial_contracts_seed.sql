-- =====================================================================
-- Seed 46: interface 'financial-contracts' (Contratos Financeiros — baixa
-- automática por forma de pagamento) —
-- prompt_contrato_financeiro_baixa_automatica.md, D1–D22 (2026-09-03).
-- Grupo "Financial" (menu Financeiro); kind 'T'. id DINÂMICO (MAX+1 —
-- lição do seed 40; nunca fixar id de interface). Idempotente.
-- Acompanha a migration 038 (setes-api): tb_financial_contract +
-- usage_preference APOSENTADA (D17) — este seed remove o campo do catálogo
-- de campos configuráveis (tb_interface_has_field da interface 16).
-- Executar após o script 45.
-- =====================================================================

USE `setes_central`;

-- Contratos Financeiros (módulo financial-contracts —
-- /api/financial-contracts ↔ /home/financial-contracts)
INSERT INTO `tb_interface`
  (`id`, `group_default`, `i18n_key`, `description`, `kind`, `position`, `created_at`, `updated_at`, `deleted`)
SELECT (SELECT COALESCE(MAX(i2.`id`), 0) + 1 FROM `tb_interface` i2),
       'Financial', 'financial-contracts', 'Financial Contracts', 'T', NULL, NOW(), NOW(), 'N'
 WHERE NOT EXISTS (SELECT 1 FROM `tb_interface`
                    WHERE `i18n_key` = 'financial-contracts' AND `deleted` = 'N');

-- Contrato da Setes (institution 1 — dev/dogfooding). Outros clientes:
-- conceder pela tela de Institutions.
INSERT IGNORE INTO `setes_setes`.`tb_institution_has_interface`
  (`tb_institution_id`, `tb_interface_id`, `active`, `created_at`, `updated_at`, `deleted`)
SELECT 1, i.`id`, 'S', NOW(), NOW(), 'N'
  FROM `tb_interface` i
 WHERE i.`deleted` = 'N' AND i.`i18n_key` = 'financial-contracts';

-- Paginação (regra: lista nova nasce paginada — seed 22)
INSERT IGNORE INTO `tb_interface_has_config`
  (`tb_interface_id`, `name`, `description`, `kind`, `options`, `default_content`, `scope`, `created_at`, `updated_at`, `deleted`)
SELECT i.`id`, 'page_size',
       'Número de itens exibidos por página na lista de pesquisa.',
       'Options', '10=10;25=25;50=50;100=100', '25', 'U', NOW(), NOW(), 'N'
  FROM `tb_interface` i
 WHERE i.`deleted` = 'N' AND i.`i18n_key` = 'financial-contracts';

-- Gate técnico do módulo /api/financial-contracts para institutions
-- EXISTENTES (novas ganham via insertDefaultFlags).
INSERT IGNORE INTO `tb_feature_flag`
  (`id`, `tb_institution_id`, `module_key`, `enabled`, `created_at`, `updated_at`, `deleted`)
SELECT (SELECT COALESCE(MAX(f2.id), 0) FROM `tb_feature_flag` f2) + i.rn,
       i.id, 'financial-contracts', TRUE, NOW(), NOW(), 'N'
FROM (
  SELECT t.id, ROW_NUMBER() OVER (ORDER BY t.id) AS rn
  FROM `tb_institution` t
  WHERE t.deleted = 'N'
    AND NOT EXISTS (SELECT 1 FROM `tb_feature_flag` f
                    WHERE f.tb_institution_id = t.id
                      AND f.module_key = 'financial-contracts')
) i;

-- D17: usage_preference aposentada — sai do catálogo de campos da tela de
-- Formas de Pagamento (interface 16). Overrides do cliente
-- (tb_institution_has_field) apontam por FK composta para este catálogo:
-- removidos antes (dev: setes_setes; outros schemas: repetir por schema).
DELETE FROM `setes_setes`.`tb_institution_has_field`
 WHERE `tb_interface_id` = 16 AND `field_name` = 'usage_preference';
DELETE FROM `tb_interface_has_field`
 WHERE `tb_interface_id` = 16 AND `field_name` = 'usage_preference';
