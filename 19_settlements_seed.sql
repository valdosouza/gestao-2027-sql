-- =====================================================================
-- Seed: 19_settlements_seed.sql — Software House Onda 5
-- (Valdo, 2026-07-19 — prompt fechado prompt_modulo_software_house.md)
--
-- Interface 21 'settlements' (Baixa de Títulos — Fases 5.5/6 do doc
-- 05-ORDEM-SERVICO: carteira, baixa com settled_code N:1, estorno
-- IMUTÁVEL por lançamento inverso, movimento banco/caixa) no grupo
-- Financial. Contrato da Setes + flag + catálogo de campos. Idempotente.
-- =====================================================================

USE `setes_central`;

INSERT IGNORE INTO `tb_interface`
  (`id`, `group_default`, `i18n_key`, `description`, `kind`, `position`, `created_at`, `updated_at`, `deleted`)
VALUES
  (21, 'Financial', 'settlements', 'Settlements', 'T', NULL, NOW(), NOW(), 'N');

INSERT IGNORE INTO `setes_setes`.`tb_institution_has_interface`
  (`tb_institution_id`, `tb_interface_id`, `active`, `created_at`, `updated_at`, `deleted`)
VALUES
  (1, 21, 'S', NOW(), NOW(), 'N');

INSERT IGNORE INTO `tb_feature_flag`
  (`id`, `tb_institution_id`, `module_key`, `enabled`, `created_at`, `updated_at`, `deleted`)
SELECT (SELECT COALESCE(MAX(f2.id), 0) FROM `tb_feature_flag` f2) + i.rn,
       i.id, 'settlements', TRUE, NOW(), NOW(), 'N'
FROM (
  SELECT t.id, ROW_NUMBER() OVER (ORDER BY t.id) AS rn
  FROM `tb_institution` t
  WHERE t.deleted = 'N'
    AND NOT EXISTS (SELECT 1 FROM `tb_feature_flag` f
                    WHERE f.tb_institution_id = t.id
                      AND f.module_key = 'settlements')
) i;

INSERT IGNORE INTO `tb_interface_has_field`
  (`tb_interface_id`, `field_name`, `table_name`, `kind`, `required`, `created_at`, `updated_at`, `deleted`)
VALUES
  (21, 'interest_value',     'tb_financial_payment', 'Float',   'N', NOW(), NOW(), 'N'),
  (21, 'late_value',         'tb_financial_payment', 'Float',   'N', NOW(), NOW(), 'N'),
  (21, 'discount_aliquot',   'tb_financial_payment', 'Float',   'N', NOW(), NOW(), 'N'),
  (21, 'paid_value',         'tb_financial_payment', 'Float',   'S', NOW(), NOW(), 'N'),
  (21, 'dt_payment',         'tb_financial_payment', 'Date',    'S', NOW(), NOW(), 'N'),
  (21, 'dt_real_payment',    'tb_financial_payment', 'Date',    'N', NOW(), NOW(), 'N'),
  (21, 'tb_bank_account_id', 'tb_financial_statement', 'Integer', 'S', NOW(), NOW(), 'N'),
  (21, 'reversal_reason',    'tb_financial_payment', 'String',  'N', NOW(), NOW(), 'N');
