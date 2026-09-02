-- =====================================================================
-- Seed 42: interfaces 'price-lists' (Tabelas de Preço) e 'services'
-- (Serviços) — prompt_modulo_services.md, D1–D7 (2026-09-01/02).
-- Grupo "Registers" (menu Cadastros); kind 'T' = VENDÁVEL (telas irmãs —
-- D6: "Serviços" hoje, "Produtos" no futuro, cada uma contratável por
-- interface; D3: a liberação a cliente COM legado é decisão comercial —
-- não conceder o contrato enquanto o sync alimentar tb_product).
-- id DINÂMICO (MAX+1 — lição do seed 40; nunca fixar id de interface).
-- Idempotente (NOT EXISTS / INSERT IGNORE). Executar após o script 41.
-- =====================================================================

USE `setes_central`;

-- Tabelas de Preço (módulo price-lists — /api/price-lists ↔ /home/price-lists)
INSERT INTO `tb_interface`
  (`id`, `group_default`, `i18n_key`, `description`, `kind`, `position`, `created_at`, `updated_at`, `deleted`)
SELECT (SELECT COALESCE(MAX(i2.`id`), 0) + 1 FROM `tb_interface` i2),
       'Registers', 'price-lists', 'Price Lists', 'T', NULL, NOW(), NOW(), 'N'
 WHERE NOT EXISTS (SELECT 1 FROM `tb_interface`
                    WHERE `i18n_key` = 'price-lists' AND `deleted` = 'N');

-- Serviços (módulo services — /api/services ↔ /home/services)
INSERT INTO `tb_interface`
  (`id`, `group_default`, `i18n_key`, `description`, `kind`, `position`, `created_at`, `updated_at`, `deleted`)
SELECT (SELECT COALESCE(MAX(i2.`id`), 0) + 1 FROM `tb_interface` i2),
       'Registers', 'services', 'Services', 'T', NULL, NOW(), NOW(), 'N'
 WHERE NOT EXISTS (SELECT 1 FROM `tb_interface`
                    WHERE `i18n_key` = 'services' AND `deleted` = 'N');

-- Contrato da Setes (institution 1 — dev/dogfooding). Outros clientes:
-- conceder pela tela de Institutions quando abandonarem o legado (D3).
INSERT IGNORE INTO `setes_setes`.`tb_institution_has_interface`
  (`tb_institution_id`, `tb_interface_id`, `active`, `created_at`, `updated_at`, `deleted`)
SELECT 1, i.`id`, 'S', NOW(), NOW(), 'N'
  FROM `tb_interface` i
 WHERE i.`deleted` = 'N' AND i.`i18n_key` IN ('price-lists', 'services');

-- Paginação (regra: lista nova nasce paginada — seed 22): page_size para
-- as duas interfaces.
INSERT IGNORE INTO `tb_interface_has_config`
  (`tb_interface_id`, `name`, `description`, `kind`, `options`, `default_content`, `scope`, `created_at`, `updated_at`, `deleted`)
SELECT i.`id`, 'page_size',
       'Número de itens exibidos por página na lista de pesquisa.',
       'Options', '10=10;25=25;50=50;100=100', '25', 'U', NOW(), NOW(), 'N'
  FROM `tb_interface` i
 WHERE i.`deleted` = 'N' AND i.`i18n_key` IN ('price-lists', 'services');

-- Gate técnico dos módulos /api/services e /api/price-lists para
-- institutions EXISTENTES (novas ganham via insertDefaultFlags).
INSERT IGNORE INTO `tb_feature_flag`
  (`id`, `tb_institution_id`, `module_key`, `enabled`, `created_at`, `updated_at`, `deleted`)
SELECT (SELECT COALESCE(MAX(f2.id), 0) FROM `tb_feature_flag` f2) + i.rn,
       i.id, 'services', TRUE, NOW(), NOW(), 'N'
FROM (
  SELECT t.id, ROW_NUMBER() OVER (ORDER BY t.id) AS rn
  FROM `tb_institution` t
  WHERE t.deleted = 'N'
    AND NOT EXISTS (SELECT 1 FROM `tb_feature_flag` f
                    WHERE f.tb_institution_id = t.id
                      AND f.module_key = 'services')
) i;

INSERT IGNORE INTO `tb_feature_flag`
  (`id`, `tb_institution_id`, `module_key`, `enabled`, `created_at`, `updated_at`, `deleted`)
SELECT (SELECT COALESCE(MAX(f2.id), 0) FROM `tb_feature_flag` f2) + i.rn,
       i.id, 'price-lists', TRUE, NOW(), NOW(), 'N'
FROM (
  SELECT t.id, ROW_NUMBER() OVER (ORDER BY t.id) AS rn
  FROM `tb_institution` t
  WHERE t.deleted = 'N'
    AND NOT EXISTS (SELECT 1 FROM `tb_feature_flag` f
                    WHERE f.tb_institution_id = t.id
                      AND f.module_key = 'price-lists')
) i;
