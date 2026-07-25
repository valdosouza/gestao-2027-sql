-- =====================================================================
-- Seed: interface 'payment-types' — Formas de Pagamento
-- (pedido do Valdo 2026-07-18)
--
-- Executar após scripts 01, 02 e 06..13.
-- INSERT IGNORE: idempotente, seguro para re-execução.
--
-- Interface de CLIENTE no grupo NOVO 'Financial' (menu "Financeiro"):
-- módulo payment_types no app (/home/payment-types) e /api/payment-types
-- na API (SEM superGuard). O catálogo é central e o cliente INICIA o
-- cadastro (existe = só vincula).
-- =====================================================================

USE `setes_central`;

INSERT IGNORE INTO `tb_interface`
  (`id`, `group_default`, `i18n_key`, `description`, `kind`, `position`, `created_at`, `updated_at`, `deleted`)
VALUES
  (16, 'Financial', 'payment-types', 'Payment Types', 'T', NULL, NOW(), NOW(), 'N');

-- Contrato da Setes; outros clientes via aba Interfaces do Institution.
INSERT IGNORE INTO `setes_setes`.`tb_institution_has_interface`
  (`tb_institution_id`, `tb_interface_id`, `active`, `created_at`, `updated_at`, `deleted`)
VALUES
  (1, 16, 'S', NOW(), NOW(), 'N');

-- Gate técnico do módulo /api/payment-types para institutions EXISTENTES
-- (novas ganham via insertDefaultFlags).
INSERT IGNORE INTO `tb_feature_flag`
  (`id`, `tb_institution_id`, `module_key`, `enabled`, `created_at`, `updated_at`, `deleted`)
SELECT (SELECT COALESCE(MAX(f2.id), 0) FROM `tb_feature_flag` f2) + i.rn,
       i.id, 'payment-types', TRUE, NOW(), NOW(), 'N'
FROM (
  SELECT t.id, ROW_NUMBER() OVER (ORDER BY t.id) AS rn
  FROM `tb_institution` t
  WHERE t.deleted = 'N'
    AND NOT EXISTS (SELECT 1 FROM `tb_feature_flag` f
                    WHERE f.tb_institution_id = t.id
                      AND f.module_key = 'payment-types')
) i;

-- Catálogo de CAMPOS da tela (Fase 2) — atributos do vínculo conforme
-- migration 012 (enable/app_mobile + configuração operacional).
INSERT IGNORE INTO `tb_interface_has_field`
  (`tb_interface_id`, `field_name`, `table_name`, `kind`, `required`, `created_at`, `updated_at`, `deleted`)
VALUES
  (16, 'id',           'tb_payment_types', 'Integer', 'S', NOW(), NOW(), 'N'),
  (16, 'description',  'tb_payment_types', 'String',  'S', NOW(), NOW(), 'N'),
  (16, 'id_nfce',      'tb_payment_types', 'String',  'N', NOW(), NOW(), 'N'),
  (16, 'enable',       'tb_institution_has_payment_types', 'Boolean', 'N', NOW(), NOW(), 'N'),
  (16, 'app_mobile',   'tb_institution_has_payment_types', 'Boolean', 'N', NOW(), NOW(), 'N'),
  (16, 'block_for_customer_blocked',  'tb_institution_has_payment_types', 'Boolean', 'N', NOW(), NOW(), 'N'),
  (16, 'block_for_customer_no_limit', 'tb_institution_has_payment_types', 'Boolean', 'N', NOW(), NOW(), 'N'),
  (16, 'max_parcels',                 'tb_institution_has_payment_types', 'Integer', 'N', NOW(), NOW(), 'N'),
  (16, 'tef',                         'tb_institution_has_payment_types', 'Boolean', 'N', NOW(), NOW(), 'N'),
  (16, 'tb_financial_plans_id_cre',   'tb_institution_has_payment_types', 'Integer', 'N', NOW(), NOW(), 'N'),
  (16, 'tb_financial_plans_id_deb',   'tb_institution_has_payment_types', 'Integer', 'N', NOW(), NOW(), 'N'),
  (16, 'usage_preference',            'tb_institution_has_payment_types', 'String',  'N', NOW(), NOW(), 'N');
