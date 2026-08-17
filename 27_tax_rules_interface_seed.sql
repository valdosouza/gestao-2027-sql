-- =====================================================================
-- Fase Faturamento Fiscal e Financeiro — Seed: interface 'tax-rules' (27)
-- (prompt_fase_faturamento_financeiro.md, decisões 1/23/28)
--
-- Executar após scripts 01, 02 e 06..26.
-- INSERT IGNORE / NOT EXISTS: idempotente, seguro para re-execução.
--
-- Interface de CLIENTE (não é Super): módulo tax-rules no app
-- (/home/tax-rules) e /api/tax-rules na API (sem superGuard — escopo por
-- institution no JWT; flag técnica 'tax-rules').
-- Cadastro da Regra de Tributação: seletor + peças por tributo
-- (presença = incidência). group_default = 'Registers'.
-- =====================================================================

USE `setes_central`;

-- id preferencial 27, resolvido dinamicamente (padrão do seed 25 — achado
-- do gate adversarial 2026-08-04: id literal pode colidir com interface
-- criada por MAX+1). NOT EXISTS por i18n_key = idempotente.
INSERT INTO `tb_interface`
  (`id`, `group_default`, `i18n_key`, `description`, `kind`, `position`, `created_at`, `updated_at`, `deleted`)
SELECT GREATEST(27, (SELECT COALESCE(MAX(i2.`id`), 0) + 1 FROM `tb_interface` i2)),
       'Registers', 'tax-rules', 'Tax Rule', 'T', NULL, NOW(), NOW(), 'N'
  FROM DUAL
 WHERE NOT EXISTS (SELECT 1 FROM `tb_interface` WHERE `i18n_key` = 'tax-rules' AND `deleted` = 'N');

-- Contrato da Setes; para outros clientes o Super concede pela aba
-- Interfaces do Institution. Resolvido por i18n_key (nunca id literal).
INSERT IGNORE INTO `setes_setes`.`tb_institution_has_interface`
  (`tb_institution_id`, `tb_interface_id`, `active`, `created_at`, `updated_at`, `deleted`)
SELECT 1, i.`id`, 'S', NOW(), NOW(), 'N'
  FROM `tb_interface` i
 WHERE i.`deleted` = 'N' AND i.`i18n_key` = 'tax-rules';

-- Gate técnico do /api/tax-rules para institutions EXISTENTES (novas ganham
-- via insertDefaultFlags). Idempotente: UNIQUE (tb_institution_id, module_key).
INSERT IGNORE INTO `tb_feature_flag`
  (`id`, `tb_institution_id`, `module_key`, `enabled`, `created_at`, `updated_at`, `deleted`)
SELECT (SELECT COALESCE(MAX(f2.id), 0) FROM `tb_feature_flag` f2) + i.rn,
       i.id, 'tax-rules', TRUE, NOW(), NOW(), 'N'
FROM (
  SELECT t.id, ROW_NUMBER() OVER (ORDER BY t.id) AS rn
  FROM `tb_institution` t
  WHERE t.deleted = 'N'
    AND NOT EXISTS (SELECT 1 FROM `tb_feature_flag` f
                    WHERE f.tb_institution_id = t.id
                      AND f.module_key = 'tax-rules')
) i;

-- Catálogo de CAMPOS da tela (Fase 2 — engine na fábrica): os campos
-- OPCIONAIS do seletor que o cliente pode apertar (required baseline 'N';
-- o técnico — origem/finalidade/flags — é do DTO). Por i18n_key.
INSERT IGNORE INTO `tb_interface_has_field`
  (`tb_interface_id`, `field_name`, `table_name`, `kind`, `required`, `created_at`, `updated_at`, `deleted`)
SELECT i.`id`, f.`field_name`, 'tb_tax_rule', f.`kind`, 'N', NOW(), NOW(), 'N'
  FROM `tb_interface` i
 CROSS JOIN (
   SELECT 'ncm' AS field_name, 'String' AS kind
   UNION ALL SELECT 'productId', 'Number'
   UNION ALL SELECT 'entityId', 'Number'
   UNION ALL SELECT 'stateId', 'Number'
   UNION ALL SELECT 'cfopId', 'String'
 ) f
 WHERE i.`deleted` = 'N'
   AND i.`i18n_key` = 'tax-rules';

-- Paginação (regra do prompt_paginacao_telas_pesquisa.md): lista NOVA nasce
-- paginada — config page_size da interface (mesmo shape do seed 22).
INSERT IGNORE INTO `tb_interface_has_config`
  (`tb_interface_id`, `name`, `description`, `kind`, `options`, `default_content`, `scope`, `created_at`, `updated_at`, `deleted`)
SELECT i.`id`, 'page_size',
       'Número de itens exibidos por página na lista de pesquisa.',
       'Options', '10=10;25=25;50=50;100=100', '25', 'U', NOW(), NOW(), 'N'
  FROM `tb_interface` i
 WHERE i.`deleted` = 'N'
   AND i.`i18n_key` = 'tax-rules';
