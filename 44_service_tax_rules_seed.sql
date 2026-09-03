-- =====================================================================
-- Seed 44: interface 'service-tax-rules' (Regras de Tributação de Serviço)
-- — prompt_regra_tributacao_servico.md, Onda 2 (2026-09-02).
-- Grupo "Registers" (menu Cadastros, ao lado de Regras de Tributação);
-- kind 'T' vendável. DDL da tabela: migration 036 (schema do cliente) +
-- sql/03 canônico. id DINÂMICO (lição do seed 40). Idempotente.
-- Executar após o 43.
-- =====================================================================

USE `setes_central`;

INSERT INTO `tb_interface`
  (`id`, `group_default`, `i18n_key`, `description`, `kind`, `position`, `created_at`, `updated_at`, `deleted`)
SELECT (SELECT COALESCE(MAX(i2.`id`), 0) + 1 FROM `tb_interface` i2),
       'Registers', 'service-tax-rules', 'Service Tax Rules', 'T', NULL, NOW(), NOW(), 'N'
 WHERE NOT EXISTS (SELECT 1 FROM `tb_interface`
                    WHERE `i18n_key` = 'service-tax-rules' AND `deleted` = 'N');

-- Contrato da Setes (institution 1 — dev/dogfooding).
INSERT IGNORE INTO `setes_setes`.`tb_institution_has_interface`
  (`tb_institution_id`, `tb_interface_id`, `active`, `created_at`, `updated_at`, `deleted`)
SELECT 1, i.`id`, 'S', NOW(), NOW(), 'N'
  FROM `tb_interface` i
 WHERE i.`deleted` = 'N' AND i.`i18n_key` = 'service-tax-rules';

-- Catálogo de CAMPOS da tela.
INSERT IGNORE INTO `tb_interface_has_field`
  (`tb_interface_id`, `field_name`, `table_name`, `kind`, `required`, `created_at`, `updated_at`, `deleted`)
SELECT i.`id`, f.`field_name`, 'tb_service_tax_rule', f.`kind`, f.`required`, NOW(), NOW(), 'N'
  FROM `tb_interface` i
  JOIN (SELECT 'tb_city_id' AS field_name, 'Integer' AS kind, 'S' AS required
        UNION ALL SELECT 'tb_service_list_id', 'String', 'S'
        UNION ALL SELECT 'aliq', 'Float', 'S'
        UNION ALL SELECT 'municipal_code', 'String', 'N'
        UNION ALL SELECT 'active', 'Boolean', 'N') f
 WHERE i.`deleted` = 'N' AND i.`i18n_key` = 'service-tax-rules';

-- Paginação (regra: lista nova nasce paginada — seed 22).
INSERT IGNORE INTO `tb_interface_has_config`
  (`tb_interface_id`, `name`, `description`, `kind`, `options`, `default_content`, `scope`, `created_at`, `updated_at`, `deleted`)
SELECT i.`id`, 'page_size',
       'Número de itens exibidos por página na lista de pesquisa.',
       'Options', '10=10;25=25;50=50;100=100', '25', 'U', NOW(), NOW(), 'N'
  FROM `tb_interface` i
 WHERE i.`deleted` = 'N' AND i.`i18n_key` = 'service-tax-rules';

-- Gate técnico /api/service-tax-rules para institutions EXISTENTES (novas
-- ganham via insertDefaultFlags).
INSERT IGNORE INTO `tb_feature_flag`
  (`id`, `tb_institution_id`, `module_key`, `enabled`, `created_at`, `updated_at`, `deleted`)
SELECT (SELECT COALESCE(MAX(f2.id), 0) FROM `tb_feature_flag` f2) + i.rn,
       i.id, 'service-tax-rules', TRUE, NOW(), NOW(), 'N'
FROM (
  SELECT t.id, ROW_NUMBER() OVER (ORDER BY t.id) AS rn
  FROM `tb_institution` t
  WHERE t.deleted = 'N'
    AND NOT EXISTS (SELECT 1 FROM `tb_feature_flag` f
                    WHERE f.tb_institution_id = t.id
                      AND f.module_key = 'service-tax-rules')
) i;
