-- =====================================================================
-- Seed: 17_partnerships_bank_accounts_seed.sql — Software House Onda 3
-- (Valdo, 2026-07-19 — prompt fechado prompt_modulo_software_house.md)
--
-- 1. Bancos FEBRABAN mais comuns no catálogo central (DP2 — referência
--    compartilhada como tb_country; INSERT IGNORE pelo UNIQUE number);
-- 2. Interface 18 'partnerships' (Parcerias — grupo Registers) e
--    19 'bank-accounts' (Contas Bancárias — grupo Financial) + contrato
--    da Setes + flags técnicas p/ institutions existentes + catálogo de
--    campos (Fase 2). Idempotente.
-- =====================================================================

USE `setes_central`;

INSERT IGNORE INTO `tb_bank` (`id`, `number`, `description`, `created_at`, `updated_at`, `deleted`)
VALUES
  ( 1, '001', 'Banco do Brasil',            NOW(), NOW(), 'N'),
  ( 2, '033', 'Santander',                  NOW(), NOW(), 'N'),
  ( 3, '041', 'Banrisul',                   NOW(), NOW(), 'N'),
  ( 4, '070', 'BRB - Banco de Brasília',    NOW(), NOW(), 'N'),
  ( 5, '077', 'Banco Inter',                NOW(), NOW(), 'N'),
  ( 6, '104', 'Caixa Econômica Federal',    NOW(), NOW(), 'N'),
  ( 7, '136', 'Unicred',                    NOW(), NOW(), 'N'),
  ( 8, '208', 'BTG Pactual',                NOW(), NOW(), 'N'),
  ( 9, '212', 'Banco Original',             NOW(), NOW(), 'N'),
  (10, '237', 'Bradesco',                   NOW(), NOW(), 'N'),
  (11, '260', 'Nu Pagamentos (Nubank)',     NOW(), NOW(), 'N'),
  (12, '290', 'PagBank (PagSeguro)',        NOW(), NOW(), 'N'),
  (13, '336', 'C6 Bank',                    NOW(), NOW(), 'N'),
  (14, '341', 'Itaú Unibanco',              NOW(), NOW(), 'N'),
  (15, '348', 'Banco XP',                   NOW(), NOW(), 'N'),
  (16, '380', 'PicPay',                     NOW(), NOW(), 'N'),
  (17, '389', 'Mercantil do Brasil',        NOW(), NOW(), 'N'),
  (18, '422', 'Banco Safra',                NOW(), NOW(), 'N'),
  (19, '623', 'Banco PAN',                  NOW(), NOW(), 'N'),
  (20, '655', 'Banco BV (Votorantim)',      NOW(), NOW(), 'N'),
  (21, '707', 'Banco Daycoval',             NOW(), NOW(), 'N'),
  (22, '748', 'Sicredi',                    NOW(), NOW(), 'N'),
  (23, '756', 'Sicoob',                     NOW(), NOW(), 'N');

INSERT IGNORE INTO `tb_interface`
  (`id`, `group_default`, `i18n_key`, `description`, `kind`, `position`, `created_at`, `updated_at`, `deleted`)
VALUES
  (18, 'Registers', 'partnerships',  'Partnerships',  'T', NULL, NOW(), NOW(), 'N'),
  (19, 'Financial', 'bank-accounts', 'Bank Accounts', 'T', NULL, NOW(), NOW(), 'N');

INSERT IGNORE INTO `setes_setes`.`tb_institution_has_interface`
  (`tb_institution_id`, `tb_interface_id`, `active`, `created_at`, `updated_at`, `deleted`)
VALUES
  (1, 18, 'S', NOW(), NOW(), 'N'),
  (1, 19, 'S', NOW(), NOW(), 'N');

INSERT IGNORE INTO `tb_feature_flag`
  (`id`, `tb_institution_id`, `module_key`, `enabled`, `created_at`, `updated_at`, `deleted`)
SELECT (SELECT COALESCE(MAX(f2.id), 0) FROM `tb_feature_flag` f2) + i.rn,
       i.id, i.module_key, TRUE, NOW(), NOW(), 'N'
FROM (
  SELECT t.id, m.module_key,
         ROW_NUMBER() OVER (ORDER BY t.id, m.module_key) AS rn
  FROM `tb_institution` t
  CROSS JOIN (SELECT 'partnerships' AS module_key
              UNION ALL SELECT 'bank-accounts') m
  WHERE t.deleted = 'N'
    AND NOT EXISTS (SELECT 1 FROM `tb_feature_flag` f
                    WHERE f.tb_institution_id = t.id
                      AND f.module_key = m.module_key)
) i;

-- Catálogo de CAMPOS (Fase 2).
INSERT IGNORE INTO `tb_interface_has_field`
  (`tb_interface_id`, `field_name`, `table_name`, `kind`, `required`, `created_at`, `updated_at`, `deleted`)
VALUES
  (18, 'id',                 'tb_partnership',          'Integer', 'S', NOW(), NOW(), 'N'),
  (18, 'description',        'tb_partnership',          'String',  'S', NOW(), NOW(), 'N'),
  (18, 'dt_record',          'tb_partnership',          'Date',    'N', NOW(), NOW(), 'N'),
  (18, 'tb_customer_id',     'tb_partnership_customer', 'Integer', 'S', NOW(), NOW(), 'N'),
  (18, 'tb_collaborator_id', 'tb_partnership_partner',  'Integer', 'S', NOW(), NOW(), 'N'),
  (18, 'rate',               'tb_partnership_partner',  'Float',   'S', NOW(), NOW(), 'N'),
  (19, 'id',           'tb_bank_account', 'Integer', 'S', NOW(), NOW(), 'N'),
  (19, 'tb_bank_id',   'tb_bank_account', 'Integer', 'S', NOW(), NOW(), 'N'),
  (19, 'dt_opening',   'tb_bank_account', 'Date',    'N', NOW(), NOW(), 'N'),
  (19, 'agency',       'tb_bank_account', 'String',  'S', NOW(), NOW(), 'N'),
  (19, 'agency_dv',    'tb_bank_account', 'String',  'N', NOW(), NOW(), 'N'),
  (19, 'number',       'tb_bank_account', 'String',  'S', NOW(), NOW(), 'N'),
  (19, 'number_dv',    'tb_bank_account', 'String',  'N', NOW(), NOW(), 'N'),
  (19, 'phone',        'tb_bank_account', 'String',  'N', NOW(), NOW(), 'N'),
  (19, 'manager',      'tb_bank_account', 'String',  'N', NOW(), NOW(), 'N'),
  (19, 'limit_value',  'tb_bank_account', 'Float',   'N', NOW(), NOW(), 'N'),
  (19, 'dt_contract',  'tb_bank_account', 'Date',    'N', NOW(), NOW(), 'N');
