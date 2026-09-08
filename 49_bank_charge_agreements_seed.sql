-- =====================================================================
-- Seed 49: interface 'bank-charge-agreements' (Carteiras de Cobrança —
-- cadastro que faltava na Onda 2 do boleto; tb_bank_charge_agreement já
-- existe desde a migration 039, o smoke a alimentava por SQL direto).
-- Grupo "Financial" (D2 do prompt do boleto); kind 'T'. id DINÂMICO
-- (MAX+1 — lição do seed 40). Idempotente. Executar após o script 48.
-- =====================================================================

USE `setes_central`;

-- Carteiras de Cobrança (módulo bank-charge-agreements —
-- /api/bank-charge-agreements ↔ /home/bank-charge-agreements)
INSERT INTO `tb_interface`
  (`id`, `group_default`, `i18n_key`, `description`, `kind`, `position`, `created_at`, `updated_at`, `deleted`)
SELECT (SELECT COALESCE(MAX(i2.`id`), 0) + 1 FROM `tb_interface` i2),
       'Financial', 'bank-charge-agreements', 'Bank Charge Agreements', 'T', NULL, NOW(), NOW(), 'N'
 WHERE NOT EXISTS (SELECT 1 FROM `tb_interface`
                    WHERE `i18n_key` = 'bank-charge-agreements' AND `deleted` = 'N');

-- Contrato da Setes (institution 1 — dev/dogfooding)
INSERT IGNORE INTO `setes_setes`.`tb_institution_has_interface`
  (`tb_institution_id`, `tb_interface_id`, `active`, `created_at`, `updated_at`, `deleted`)
SELECT 1, i.`id`, 'S', NOW(), NOW(), 'N'
  FROM `tb_interface` i
 WHERE i.`deleted` = 'N' AND i.`i18n_key` = 'bank-charge-agreements';

-- Paginação (regra: lista nova nasce paginada — seed 22)
INSERT IGNORE INTO `tb_interface_has_config`
  (`tb_interface_id`, `name`, `description`, `kind`, `options`, `default_content`, `scope`, `created_at`, `updated_at`, `deleted`)
SELECT i.`id`, 'page_size',
       'Número de itens exibidos por página na lista de pesquisa.',
       'Options', '10=10;25=25;50=50;100=100', '25', 'U', NOW(), NOW(), 'N'
  FROM `tb_interface` i
 WHERE i.`deleted` = 'N' AND i.`i18n_key` = 'bank-charge-agreements';

-- Gate técnico do módulo /api/bank-charge-agreements para institutions EXISTENTES
INSERT IGNORE INTO `tb_feature_flag`
  (`id`, `tb_institution_id`, `module_key`, `enabled`, `created_at`, `updated_at`, `deleted`)
SELECT (SELECT COALESCE(MAX(f2.id), 0) FROM `tb_feature_flag` f2) + i.rn,
       i.id, 'bank-charge-agreements', TRUE, NOW(), NOW(), 'N'
FROM (
  SELECT t.id, ROW_NUMBER() OVER (ORDER BY t.id) AS rn
  FROM `tb_institution` t
  WHERE t.deleted = 'N'
    AND NOT EXISTS (SELECT 1 FROM `tb_feature_flag` f
                    WHERE f.tb_institution_id = t.id
                      AND f.module_key = 'bank-charge-agreements')
) i;

-- Catálogo de campos configuráveis (baseline técnico — molde seed 47)
INSERT IGNORE INTO `tb_interface_has_field`
  (`tb_interface_id`, `field_name`, `table_name`, `kind`, `required`, `created_at`, `updated_at`, `deleted`)
SELECT i.`id`, f.`field_name`, 'tb_bank_charge_agreement', f.`kind`, f.`required`, NOW(), NOW(), 'N'
  FROM `tb_interface` i
  JOIN (
        SELECT 'agreement' AS field_name, 'String' AS kind, 'S' AS required
        UNION ALL SELECT 'tb_bank_account_id', 'Integer', 'S'
        UNION ALL SELECT 'accept',            'Boolean', 'N'
        UNION ALL SELECT 'aliq_discount',      'Float',   'N'
        UNION ALL SELECT 'aliq_interest',      'Float',   'N'
        UNION ALL SELECT 'aliq_late',          'Float',   'N'
        UNION ALL SELECT 'value_late_min',     'Float',   'N'
        UNION ALL SELECT 'aliq_fine',          'Float',   'N'
        UNION ALL SELECT 'value_fine',         'Float',   'N'
        UNION ALL SELECT 'value_rate',         'Float',   'N'
        UNION ALL SELECT 'instruction',        'String',  'N'
        UNION ALL SELECT 'protest',            'Boolean', 'N'
        UNION ALL SELECT 'day_protest',        'Integer', 'N'
        UNION ALL SELECT 'active',             'Boolean', 'N'
        UNION ALL SELECT 'our_number_next',    'Integer', 'N'
       ) f
 WHERE i.`i18n_key` = 'bank-charge-agreements' AND i.`deleted` = 'N';
